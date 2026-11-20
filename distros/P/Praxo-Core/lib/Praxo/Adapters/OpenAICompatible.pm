package Praxo::Adapters::OpenAICompatible;

use strict;
use warnings;
use HTTP::Tiny ();
use Praxo::Errors qw(praxo_error);
use Praxo::Json ();
use Praxo::Models ();

sub new {
    my ($class, %args) = @_;
    my $base_url = $args{base_url} // '';
    $base_url =~ s{/$}{};
    return bless {
        base_url => $base_url,
        model => $args{model} // '',
        api_key => $args{api_key},
        transport => $args{transport},
        stream_transport => $args{stream_transport},
        timeout => $args{timeout} // 60,
    }, $class;
}

sub generate {
    my ($self, $request) = @_;
    my $payload = _payload($self->{model}, $request);
    my $data = $self->{transport}
        ? $self->{transport}->('/chat/completions', $payload)
        : $self->_post('/chat/completions', $payload);
    return _parse_response($data);
}

sub generate_stream {
    my ($self, $request, $on_delta) = @_;
    my $payload = _payload($self->{model}, $request);
    $payload->{stream} = Praxo::Json::true_value();
    my $text = $self->{stream_transport}
        ? $self->{stream_transport}->('/chat/completions', $payload)
        : $self->_post_stream('/chat/completions', $payload);
    praxo_error('PROVIDER_HTTP', 'stream transport must return SSE text')
        if ref($text) || !defined $text;
    return _parse_sse($text, $on_delta);
}

sub _payload {
    my ($model, $request) = @_;
    my @messages = map { _message_payload($_) } @{ $request->{messages} // [] };
    my @tools = map {
        {
            type => 'function',
            function => {
                name => $_->{name},
                description => $_->{description} // '',
                parameters => $_->{parameters} // { type => 'object' },
            },
        }
    } @{ $request->{tools} // [] };
    my %payload = (
        model => $model,
        messages => \@messages,
    );
    $payload{tools} = \@tools if @tools;
    $payload{tool_choice} = $request->{toolChoice} if defined $request->{toolChoice};
    $payload{response_format} = $request->{responseFormat} if defined $request->{responseFormat};
    $payload{temperature} = $request->{temperature} if defined $request->{temperature};
    return \%payload;
}

sub _message_payload {
    my ($message) = @_;
    my $content = $message->{content};
    if ((!defined $content || $content eq '') && ref($message->{contentBlocks}) eq 'ARRAY') {
        $content = join '', map { $_->{text} // '' }
            grep { ($_->{type} // '') eq 'text' } @{ $message->{contentBlocks} };
    }
    my %out = (role => $message->{role}, content => $content);
    if ($message->{role} eq Praxo::Models::ASSISTANT()
        && ref($message->{toolCalls}) eq 'ARRAY' && @{ $message->{toolCalls} }) {
        $out{tool_calls} = [
            map {
                {
                    id => $_->{id},
                    type => 'function',
                    function => {
                        name => $_->{name},
                        arguments => Praxo::Json::stringify($_->{arguments} // {}),
                    },
                }
            } @{ $message->{toolCalls} }
        ];
    }
    if ($message->{role} eq Praxo::Models::TOOL()
        && defined $message->{toolId} && $message->{toolId} ne '') {
        $out{tool_call_id} = $message->{toolId};
    }
    return \%out;
}

sub _parse_response {
    my ($data) = @_;
    my $choice = ref($data->{choices}) eq 'ARRAY' ? $data->{choices}[0] : undef;
    $choice = {} unless ref($choice) eq 'HASH';
    my $message = ref($choice->{message}) eq 'HASH' ? $choice->{message} : {};
    my @tool_calls = map {
        my $function = ref($_->{function}) eq 'HASH' ? $_->{function} : {};
        my $arguments = $function->{arguments};
        if (defined $arguments && !ref($arguments) && $arguments ne '') {
            $arguments = Praxo::Json::parse($arguments);
        }
        Praxo::Models::tool_call(
            id => $_->{id} // '',
            name => $function->{name} // '',
            arguments => ref($arguments) eq 'HASH' ? $arguments : {},
        )
    } grep { ref($_) eq 'HASH' } @{ ref($message->{tool_calls}) eq 'ARRAY' ? $message->{tool_calls} : [] };
    my $usage = ref($data->{usage}) eq 'HASH' ? $data->{usage} : {};
    return Praxo::Models::response(
        message => Praxo::Models::message_assistant($message->{content}, \@tool_calls),
        usage => Praxo::Models::usage(
            input_tokens => $usage->{prompt_tokens} // 0,
            output_tokens => $usage->{completion_tokens} // 0,
        ),
        finish_reason => $choice->{finish_reason},
    );
}

sub _parse_sse {
    my ($text, $on_delta) = @_;
    my $content = '';
    my %calls;
    my ($input_tokens, $output_tokens, $finish_reason, $done) = (0, 0, undef, 0);
    for my $raw (split /\n/, $text) {
        my $line = $raw;
        $line =~ s/^\s+|\s+$//g;
        next unless $line =~ /^data:\s*(.*)$/;
        my $chunk = $1;
        $chunk =~ s/^\s+|\s+$//g;
        next if $chunk eq '';
        if ($chunk eq '[DONE]') {
            $done = 1;
            last;
        }
        my $event = eval { Praxo::Json::parse($chunk) };
        praxo_error('MODEL_STREAM', 'invalid SSE packet')
            unless ref($event) eq 'HASH';
        if (ref($event->{usage}) eq 'HASH') {
            $input_tokens = $event->{usage}{prompt_tokens} // 0;
            $output_tokens = $event->{usage}{completion_tokens} // 0;
        }
        my $choices = ref($event->{choices}) eq 'ARRAY' ? $event->{choices} : [];
        for my $choice (@$choices) {
            next unless ref($choice) eq 'HASH';
            my $delta = ref($choice->{delta}) eq 'HASH' ? $choice->{delta} : {};
            my $piece = $delta->{content};
            if (defined $piece && !ref($piece) && $piece ne '') {
                $content .= $piece;
                $on_delta->($piece);
            }
            my $items = ref($delta->{tool_calls}) eq 'ARRAY' ? $delta->{tool_calls} : [];
            for my $item (@$items) {
                next unless ref($item) eq 'HASH';
                my $index = defined $item->{index} ? $item->{index} : scalar(keys %calls);
                my $slot = $calls{$index} //= { id => '', name => '', arguments => '' };
                $slot->{id} .= $item->{id}
                    if defined $item->{id} && !ref($item->{id});
                my $function = ref($item->{function}) eq 'HASH' ? $item->{function} : {};
                $slot->{name} .= $function->{name}
                    if defined $function->{name} && !ref($function->{name});
                $slot->{arguments} .= $function->{arguments}
                    if defined $function->{arguments} && !ref($function->{arguments});
            }
            if (exists $choice->{finish_reason} && defined $choice->{finish_reason}) {
                $finish_reason = $choice->{finish_reason};
                $done = 1;
            }
        }
    }
    praxo_error('MODEL_STREAM', 'stream ended before completion') unless $done;
    my @tool_calls;
    for my $index (sort { $a <=> $b } keys %calls) {
        my $slot = $calls{$index};
        next if $slot->{name} eq '';
        my $arguments = {};
        if ($slot->{arguments} ne '') {
            my $parsed = eval { Praxo::Json::parse($slot->{arguments}) };
            praxo_error('PROVIDER_JSON', 'provider returned invalid tool arguments')
                unless ref($parsed) eq 'HASH';
            $arguments = $parsed;
        }
        push @tool_calls, Praxo::Models::tool_call(
            id => $slot->{id},
            name => $slot->{name},
            arguments => $arguments,
        );
    }
    return Praxo::Models::response(
        message => Praxo::Models::message_assistant($content, \@tool_calls),
        usage => Praxo::Models::usage(
            input_tokens => $input_tokens,
            output_tokens => $output_tokens,
        ),
        finish_reason => $finish_reason,
    );
}

sub _post_stream {
    my ($self, $path, $payload) = @_;
    praxo_error('PROVIDER_HTTP', 'provider base URL is required')
        unless $self->{base_url} ne '';
    my %headers = (
        'content-type' => 'application/json',
        'accept' => 'text/event-stream',
    );
    $headers{authorization} = 'Bearer ' . $self->{api_key}
        if defined $self->{api_key} && $self->{api_key} ne '';
    my $http = HTTP::Tiny->new(timeout => $self->{timeout});
    my $response = $http->post(
        $self->{base_url} . $path,
        {
            headers => \%headers,
            content => Praxo::Json::stringify($payload),
        },
    );
    praxo_error(
        'PROVIDER_HTTP',
        'provider returned HTTP ' . ($response->{status} // 0) . ': ' . ($response->{content} // ''),
    ) unless $response->{success};
    return $response->{content};
}

sub _post {
    my ($self, $path, $payload) = @_;
    praxo_error('PROVIDER_HTTP', 'provider base URL is required')
        unless $self->{base_url} ne '';
    my %headers = ('content-type' => 'application/json');
    $headers{authorization} = 'Bearer ' . $self->{api_key}
        if defined $self->{api_key} && $self->{api_key} ne '';
    my $http = HTTP::Tiny->new(timeout => $self->{timeout});
    my $response = $http->post(
        $self->{base_url} . $path,
        {
            headers => \%headers,
            content => Praxo::Json::stringify($payload),
        },
    );
    praxo_error(
        'PROVIDER_HTTP',
        'provider returned HTTP ' . ($response->{status} // 0) . ': ' . ($response->{content} // ''),
    ) unless $response->{success};
    return Praxo::Json::parse($response->{content});
}

1;

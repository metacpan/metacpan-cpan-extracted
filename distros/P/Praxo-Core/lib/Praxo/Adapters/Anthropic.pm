package Praxo::Adapters::Anthropic;

use strict;
use warnings;
use HTTP::Tiny ();
use Praxo::Errors qw(praxo_error);
use Praxo::Json ();
use Praxo::Models ();

sub new {
    my ($class, %args) = @_;
    my $base_url = $args{base_url} // 'https://api.anthropic.com';
    $base_url =~ s{/$}{};
    return bless {
        base_url => $base_url,
        model => $args{model} // '',
        api_key => $args{api_key},
        version => $args{version} // '2023-06-01',
        max_tokens => $args{max_tokens} // 1024,
        transport => $args{transport},
        stream_transport => $args{stream_transport},
        timeout => $args{timeout} // 60,
    }, $class;
}

sub generate {
    my ($self, $request) = @_;
    praxo_error('MODEL_CONFIG', 'anthropic: API key is required')
        unless defined $self->{api_key} && $self->{api_key} ne '';
    praxo_error('MODEL_CONFIG', 'anthropic: model is required')
        unless $self->{model} ne '';
    my $payload = _payload($self, $request);
    my $data = $self->{transport}
        ? $self->{transport}->('/v1/messages', $payload)
        : $self->_post('/v1/messages', $payload);
    return _parse_response($data);
}

sub generate_stream {
    my ($self, $request, $on_delta) = @_;
    praxo_error('MODEL_CONFIG', 'anthropic: API key is required')
        unless defined $self->{api_key} && $self->{api_key} ne '';
    praxo_error('MODEL_CONFIG', 'anthropic: model is required')
        unless $self->{model} ne '';
    my $payload = _payload($self, $request, 1);
    my $text = $self->{stream_transport}
        ? $self->{stream_transport}->('/v1/messages', $payload)
        : $self->_post_stream('/v1/messages', $payload);
    praxo_error('PROVIDER_HTTP', 'stream transport must return SSE text')
        if ref($text) || !defined $text;
    return _parse_sse($text, $on_delta);
}

sub _payload {
    my ($self, $request, $stream) = @_;
    my ($system, $messages) = _build_messages($request->{messages});
    my %payload = (
        model => $self->{model},
        max_tokens => $self->{max_tokens},
        messages => $messages,
    );
    $payload{system} = $system if $system ne '';
    my @tools = map {
        {
            name => $_->{name},
            description => $_->{description} // '',
            input_schema => $_->{parameters} // { type => 'object', properties => {} },
        }
    } @{ $request->{tools} // [] };
    if (@tools) {
        $payload{tools} = \@tools;
        my $choice = _tool_choice($request->{toolChoice});
        $payload{tool_choice} = $choice if $choice;
    }
    $payload{temperature} = $request->{temperature}
        if defined $request->{temperature} && $request->{temperature} != 0;
    $payload{stream} = Praxo::Json::true_value() if $stream;
    return \%payload;
}

sub _build_messages {
    my ($messages) = @_;
    my @system;
    my @out;
    my @pending;
    my $flush = sub {
        return unless @pending;
        push @out, { role => 'user', content => [@pending] };
        @pending = ();
    };
    for my $message (@{ $messages // [] }) {
        if ($message->{role} eq Praxo::Models::SYSTEM()) {
            push @system, $message->{content}
                if defined $message->{content} && $message->{content} ne '';
            next;
        }
        if ($message->{role} eq Praxo::Models::TOOL()) {
            push @pending, {
                type => 'tool_result',
                tool_use_id => $message->{toolId} // '',
                content => $message->{content} // '',
            };
            next;
        }
        $flush->();
        my $content = _message_content($message);
        push @out, { role => $message->{role}, content => $content } if @$content;
    }
    $flush->();
    return (join("\n\n", @system), \@out);
}

sub _message_content {
    my ($message) = @_;
    my @content;
    push @content, { type => 'text', text => $message->{content} }
        if defined $message->{content} && $message->{content} ne '';
    for my $block (@{ $message->{contentBlocks} // [] }) {
        push @content, { type => 'text', text => $block->{text} }
            if ($block->{type} // '') eq 'text'
            && defined $block->{text} && $block->{text} ne '';
    }
    for my $call (@{ $message->{toolCalls} // [] }) {
        push @content, {
            type => 'tool_use',
            id => $call->{id} // '',
            name => $call->{name} // '',
            input => $call->{arguments} // {},
        };
    }
    return \@content;
}

sub _tool_choice {
    my ($choice) = @_;
    return { type => 'auto' } if defined $choice && $choice eq 'auto';
    return { type => 'any' } if defined $choice && $choice eq 'required';
    return { type => 'none' } if defined $choice && $choice eq 'none';
    return undef;
}

sub _parse_sse {
    my ($text, $on_delta) = @_;
    my $content = '';
    my %calls;
    my ($input_tokens, $output_tokens, $cached_tokens, $stop_reason, $stopped) =
        (0, 0, 0, undef, 0);
    for my $raw (split /\n/, $text) {
        my $line = $raw;
        $line =~ s/^\s+|\s+$//g;
        next unless $line =~ /^data:\s*(.*)$/;
        my $chunk = $1;
        $chunk =~ s/^\s+|\s+$//g;
        next if $chunk eq '';
        my $event = eval { Praxo::Json::parse($chunk) };
        praxo_error('MODEL_STREAM', 'anthropic: invalid stream chunk')
            unless ref($event) eq 'HASH';
        my $type = $event->{type} // '';
        if ($type eq 'message_start') {
            my $usage = $event->{message}{usage} // {};
            $input_tokens = $usage->{input_tokens} // 0;
            $cached_tokens = $usage->{cache_read_input_tokens} // 0;
        } elsif ($type eq 'content_block_start') {
            my $index = $event->{index} // 0;
            my $block = $event->{content_block} // {};
            if (($block->{type} // '') eq 'tool_use') {
                $calls{$index} = {
                    id => $block->{id} // '',
                    name => $block->{name} // '',
                    arguments => '',
                };
            }
        } elsif ($type eq 'content_block_delta') {
            my $index = $event->{index} // 0;
            my $delta = $event->{delta} // {};
            my $delta_type = $delta->{type} // '';
            if ($delta_type eq 'text_delta') {
                my $piece = $delta->{text} // '';
                if ($piece ne '') {
                    $content .= $piece;
                    $on_delta->($piece);
                }
            } elsif ($delta_type eq 'input_json_delta' && exists $calls{$index}) {
                $calls{$index}{arguments} .= $delta->{partial_json} // '';
            }
        } elsif ($type eq 'message_delta') {
            $stop_reason = $event->{delta}{stop_reason} // $stop_reason;
            $output_tokens = $event->{usage}{output_tokens} // $output_tokens;
        } elsif ($type eq 'message_stop') {
            $stopped = 1;
        } elsif ($type eq 'error') {
            praxo_error('MODEL_STREAM', 'anthropic: stream error');
        }
    }
    praxo_error('MODEL_STREAM', 'anthropic: stream ended before completion')
        unless $stopped || defined $stop_reason;
    my @tool_calls;
    for my $index (sort { $a <=> $b } keys %calls) {
        my $call = $calls{$index};
        next if $call->{name} eq '';
        my $arguments = {};
        if ($call->{arguments} ne '') {
            my $parsed = eval { Praxo::Json::parse($call->{arguments}) };
            praxo_error('PROVIDER_JSON', 'anthropic: invalid tool arguments')
                unless ref($parsed) eq 'HASH';
            $arguments = $parsed;
        }
        push @tool_calls, Praxo::Models::tool_call(
            id => $call->{id},
            name => $call->{name},
            arguments => $arguments,
        );
    }
    return Praxo::Models::response(
        message => Praxo::Models::message_assistant($content, \@tool_calls),
        usage => Praxo::Models::usage(
            input_tokens => $input_tokens,
            output_tokens => $output_tokens,
            cached_tokens => $cached_tokens,
        ),
        finish_reason => $stop_reason,
    );
}

sub _post_stream {
    my ($self, $path, $payload) = @_;
    my %headers = (
        'content-type' => 'application/json',
        'accept' => 'text/event-stream',
        'x-api-key' => $self->{api_key},
        'anthropic-version' => $self->{version},
    );
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

sub _parse_response {
    my ($data) = @_;
    praxo_error('MODEL_HTTP', 'anthropic: ' . ($data->{error}{message} // 'error'))
        if ref($data->{error}) eq 'HASH';
    my $text = '';
    my @calls;
    for my $block (@{ $data->{content} // [] }) {
        if (($block->{type} // '') eq 'text') {
            $text .= $block->{text} // '';
        } elsif (($block->{type} // '') eq 'tool_use') {
            push @calls, Praxo::Models::tool_call(
                id => $block->{id} // '',
                name => $block->{name} // '',
                arguments => $block->{input} // {},
            );
        }
    }
    my $usage = ref($data->{usage}) eq 'HASH' ? $data->{usage} : {};
    my $response = Praxo::Models::response(
        message => Praxo::Models::message_assistant($text, \@calls),
        usage => Praxo::Models::usage(
            input_tokens => $usage->{input_tokens} // 0,
            output_tokens => $usage->{output_tokens} // 0,
            cached_tokens => $usage->{cache_read_input_tokens} // 0,
        ),
        finish_reason => $data->{stop_reason},
    );
    return $response;
}

sub _post {
    my ($self, $path, $payload) = @_;
    my %headers = (
        'content-type' => 'application/json',
        'x-api-key' => $self->{api_key},
        'anthropic-version' => $self->{version},
    );
    my $http = HTTP::Tiny->new(timeout => $self->{timeout});
    my $response = $http->post(
        $self->{base_url} . $path,
        { headers => \%headers, content => Praxo::Json::stringify($payload) },
    );
    praxo_error(
        'PROVIDER_HTTP',
        'provider returned HTTP ' . ($response->{status} // 0) . ': ' . ($response->{content} // ''),
    ) unless $response->{success};
    return Praxo::Json::parse($response->{content});
}

1;

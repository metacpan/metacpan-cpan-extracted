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

sub _payload {
    my ($self, $request) = @_;
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

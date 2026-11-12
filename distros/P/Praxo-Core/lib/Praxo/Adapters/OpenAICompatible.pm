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

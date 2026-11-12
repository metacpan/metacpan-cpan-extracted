package Praxo::Adapters::Gemini;

use strict;
use warnings;
use HTTP::Tiny ();
use Praxo::Errors qw(praxo_error);
use Praxo::Json ();
use Praxo::Models ();

sub new {
    my ($class, %args) = @_;
    my $base_url = $args{base_url} // 'https://generativelanguage.googleapis.com';
    $base_url =~ s{/$}{};
    return bless {
        base_url => $base_url,
        model => $args{model} // '',
        api_key => $args{api_key},
        max_output_tokens => $args{max_output_tokens} // 0,
        transport => $args{transport},
        timeout => $args{timeout} // 60,
    }, $class;
}

sub generate {
    my ($self, $request) = @_;
    praxo_error('MODEL_CONFIG', 'gemini: API key is required')
        unless defined $self->{api_key} && $self->{api_key} ne '';
    praxo_error('MODEL_CONFIG', 'gemini: model is required')
        unless $self->{model} ne '';
    my $payload = _payload($self, $request);
    my $path = '/v1beta/models/' . _escape($self->{model})
        . ':generateContent';
    my $data = $self->{transport}
        ? $self->{transport}->($path, $payload)
        : $self->_post($path, $payload);
    return _parse_response($data);
}

sub _payload {
    my ($self, $request) = @_;
    my ($system, $contents) = _build_contents($request->{messages});
    my %payload = (contents => $contents);
    $payload{system_instruction} = { parts => $system } if @$system;
    my @declarations = map {
        {
            name => $_->{name},
            description => $_->{description} // '',
            parameters => $_->{parameters} // { type => 'object', properties => {} },
        }
    } @{ $request->{tools} // [] };
    if (@declarations) {
        $payload{tools} = [{ functionDeclarations => \@declarations }];
        $payload{toolConfig} = {
            functionCallingConfig => {
                mode => _tool_mode($request->{toolChoice}),
            },
        };
    }
    if ((defined $request->{temperature} && $request->{temperature} != 0)
        || $self->{max_output_tokens} > 0) {
        $payload{generationConfig} = {
            temperature => $request->{temperature} // 0,
            maxOutputTokens => $self->{max_output_tokens},
        };
    }
    return \%payload;
}

sub _build_contents {
    my ($messages) = @_;
    my @system;
    my @out;
    my @pending;
    my %names;
    my $flush = sub {
        return unless @pending;
        push @out, { role => 'user', parts => [@pending] };
        @pending = ();
    };
    for my $message (@{ $messages // [] }) {
        if ($message->{role} eq Praxo::Models::SYSTEM()) {
            push @system, { text => $message->{content} }
                if defined $message->{content} && $message->{content} ne '';
            next;
        }
        if ($message->{role} eq Praxo::Models::TOOL()) {
            my $name = $names{$message->{toolId} // ''} // $message->{toolId} // 'tool';
            push @pending, {
                functionResponse => {
                    name => $name,
                    response => { result => $message->{content} // '' },
                },
            };
            next;
        }
        $flush->();
        my $parts = _message_parts($message);
        if (@$parts) {
            push @out, {
                role => $message->{role} eq Praxo::Models::ASSISTANT() ? 'model' : 'user',
                parts => $parts,
            };
        }
        for my $call (@{ $message->{toolCalls} // [] }) {
            $names{$call->{id}} = $call->{name}
                if defined $call->{id} && $call->{id} ne ''
                && defined $call->{name} && $call->{name} ne '';
        }
    }
    $flush->();
    return (\@system, \@out);
}

sub _message_parts {
    my ($message) = @_;
    my @parts;
    push @parts, { text => $message->{content} }
        if defined $message->{content} && $message->{content} ne '';
    for my $block (@{ $message->{contentBlocks} // [] }) {
        push @parts, { text => $block->{text} }
            if ($block->{type} // '') eq 'text'
            && defined $block->{text} && $block->{text} ne '';
    }
    for my $call (@{ $message->{toolCalls} // [] }) {
        push @parts, {
            functionCall => {
                name => $call->{name} // '',
                args => $call->{arguments} // {},
            },
        };
    }
    return \@parts;
}

sub _escape {
    my ($value) = @_;
    $value =~ s/([^A-Za-z0-9._~-])/sprintf("%%%02X", ord($1))/ge;
    return $value;
}

sub _tool_mode {
    my ($choice) = @_;
    return 'ANY' if defined $choice && $choice eq 'required';
    return 'NONE' if defined $choice && $choice eq 'none';
    return 'AUTO';
}

sub _parse_response {
    my ($data) = @_;
    praxo_error('MODEL_HTTP', 'gemini: ' . ($data->{error}{message} // 'error'))
        if ref($data->{error}) eq 'HASH';
    my $candidate = ref($data->{candidates}) eq 'ARRAY'
        ? $data->{candidates}[0] : undef;
    praxo_error('MODEL_HTTP', 'gemini: empty response')
        unless ref($candidate) eq 'HASH';
    my $text = '';
    my @calls;
    for my $part (@{ $candidate->{content}{parts} // [] }) {
        $text .= $part->{text} // '' if defined $part->{text};
        if (ref($part->{functionCall}) eq 'HASH') {
            push @calls, Praxo::Models::tool_call(
                id => 'call-' . (scalar(@calls) + 1),
                name => $part->{functionCall}{name} // '',
                arguments => $part->{functionCall}{args} // {},
            );
        }
    }
    my $usage = ref($data->{usageMetadata}) eq 'HASH' ? $data->{usageMetadata} : {};
    return Praxo::Models::response(
        message => Praxo::Models::message_assistant($text, \@calls),
        usage => Praxo::Models::usage(
            input_tokens => $usage->{promptTokenCount} // 0,
            output_tokens => $usage->{candidatesTokenCount} // 0,
            cached_tokens => $usage->{cachedContentTokenCount} // 0,
        ),
        finish_reason => $candidate->{finishReason},
    );
}

sub _post {
    my ($self, $path, $payload) = @_;
    my %headers = (
        'content-type' => 'application/json',
        'x-goog-api-key' => $self->{api_key},
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

package RT::Extension::AI::Provider::Claude;

use strict;
use warnings;

use base 'RT::Extension::AI::Provider';

use JSON;

# Anthropic requires this header on every request. Pin a known-good version;
# see https://docs.anthropic.com/en/api/versioning
our $ANTHROPIC_VERSION = '2023-06-01';

sub default_headers {
    my ( $class, $config ) = @_;
    return {
        'x-api-key'         => $config->{api_key},
        'anthropic-version' => $config->{anthropic_version} || $ANTHROPIC_VERSION,
        'Content-Type'      => 'application/json',
    };
}

sub _process_request {
    my ( $self, %args ) = @_;
    my $ua = $self->{ua};

    my $model_config = $args{model_config} || {};

    my $prompt   = $args{prompt};
    my $raw_text = $args{raw_text};

    my $request_payload = {
        model      => $model_config->{name},
        # max_tokens is required by the Anthropic Messages API.
        max_tokens => $model_config->{max_tokens} || 1024,
    };

    # The Anthropic Messages API requires non-empty user content and treats the
    # system prompt as an optional top-level field. Some features (e.g. the
    # TicketSQL generator) put the entire query in the prompt and send no
    # raw_text, so when raw_text is empty fall back to sending the prompt as the
    # user message rather than an empty one (which 400s).
    if ( defined $raw_text && length $raw_text ) {
        $request_payload->{system} = $prompt
            if defined $prompt && length $prompt;
        $request_payload->{messages}
            = [ { role => 'user', content => $raw_text } ];
    }
    else {
        $request_payload->{messages}
            = [ { role => 'user', content => $prompt } ];
    }

    # Newer Claude models (Opus 4.7+) reject temperature with a 400, so only
    # send it when the configuration explicitly sets one.
    $request_payload->{temperature} = $model_config->{temperature}
        if defined $model_config->{temperature};

    # Which thinking settings a model accepts varies by model and effort, so
    # send one only when configured rather than choosing a default here.
    $request_payload->{thinking} = $model_config->{thinking}
        if ref $model_config->{thinking} eq 'HASH';

    my $response = $ua->post(
        $self->{api_url},
        Content      => encode_json($request_payload),
        Content_Type => 'application/json'
    );

    if ( $response->is_success ) {
        my $content = decode_json( $response->decoded_content );

        # The model may decline for safety reasons; content is then empty.
        if ( ( $content->{stop_reason} || '' ) eq 'refusal' ) {
            return {
                success => 0,
                error   => "Request refused by the model",
                raw     => $content,
            };
        }

        # Models that think return thinking blocks before the text, so the
        # first block is not necessarily the answer.
        my $result = join '',
            map { $_->{text} // '' }
            grep { ref $_ eq 'HASH' && ( $_->{type} // '' ) eq 'text' }
            @{ ref $content->{content} eq 'ARRAY' ? $content->{content} : [] };
        return {
            success => 0,
            error   => "No content in response",
            raw     => $content,
            }
            unless length $result;

        return {
            success => 1,
            result  => $result,
            raw     => $content,
        };
    } else {
        # Anthropic returns a JSON error body explaining the failure; log it so
        # 400s (bad model name, unsupported parameter, etc.) are diagnosable.
        RT->Logger->debug(
            "Claude API request failed: " . $response->status_line
            . "; response body: " . ( $response->decoded_content // '' ) );
        return {
            success => 0,
            error   => $response->status_line,
            raw     => $response->decoded_content,
        };
    }
}

sub _usage {
    my ( $self, $raw ) = @_;
    return {} unless ref $raw eq 'HASH' && ref $raw->{usage} eq 'HASH';

    my $usage = $raw->{usage};
    return {
        input_tokens  => $usage->{input_tokens},
        output_tokens => $usage->{output_tokens},
    };
}

1;

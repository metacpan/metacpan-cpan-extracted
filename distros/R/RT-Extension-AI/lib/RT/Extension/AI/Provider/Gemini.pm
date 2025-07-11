package RT::Extension::AI::Provider::Gemini;

use strict;
use warnings;

use base 'RT::Extension::AI::Provider';

use JSON;

sub default_headers {
    my ( $class, $config ) = @_;
    return { 'x-goog-api-key' => $config->{api_key} };
}

sub process_request {
    my ( $self, %args ) = @_;
    my $ua = $self->{ua};

    my $request_payload = {
        contents => [
            {   role  => "user",
                parts =>
                    [ { text => $args{prompt} . "\n" . $args{raw_text} } ],
            }
        ]
    };

    my $response = $ua->post(
        $self->{api_url},
        Content      => encode_json($request_payload),
        Content_Type => 'application/json'
    );

    if ( $response->is_success ) {
        my $content = decode_json( $response->decoded_content );

        my $candidate = $content->{candidates}[0];
        return {
            success => 0,
            error   => "No candidates in response",
            raw     => $content
            }
            unless $candidate;

        my $result = $candidate->{content}{parts}[0]{text};
        return {
            success => 1,
            result  => $result,
            raw     => $content,
        };
    } else {
        return {
            success => 0,
            error   => $response->status_line,
            raw     => $response->decoded_content,
        };
    }
}

1;

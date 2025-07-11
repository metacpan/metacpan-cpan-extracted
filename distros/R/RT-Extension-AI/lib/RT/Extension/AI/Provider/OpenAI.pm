package RT::Extension::AI::Provider::OpenAI;

use strict;
use warnings;

use base 'RT::Extension::AI::Provider';

use JSON;

sub process_request {
    my ( $self, %args ) = @_;
    my $ua = $self->{ua};

    my $request_payload = {
        model    => $args{model_config}->{name},
        messages => [
            { role => 'system', content => $args{prompt} },
            { role => 'user',   content => $args{raw_text} },
        ],
        max_tokens  => $args{model_config}->{max_tokens},
        temperature => $args{model_config}->{temperature},
    };

    my $response = $ua->post(
        $self->{api_url},
        Content      => encode_json($request_payload),
        Content_Type => 'application/json'
    );

    if ( $response->is_success ) {
        my $content = decode_json( $response->decoded_content );

        return {
            success => 1,
            result  => $content->{choices}[0]{message}{content},
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

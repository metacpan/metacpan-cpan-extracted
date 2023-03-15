package OpenAI::API::Request;

use JSON::MaybeXS;
use LWP::UserAgent;

use Moo;
use strictures 2;
use namespace::clean;

use OpenAI::API;

sub endpoint {
    die "Must be implemented";
}

sub method {
    die "Must be implemented";
}

sub send {
    my ($self, $api) = @_;

    $api //= OpenAI::API->new();

    return
          $self->method eq 'POST' ? $self->_post($api)
        : $self->method eq 'GET'  ? $self->_get($api)
        :                           die "Invalid method";
}

sub _get {
    my ($self, $api) = @_;

    my $endpoint = $self->endpoint();
    my %params   = %{$self};

    my $req = HTTP::Request->new(
        GET => "$api->{api_base}/$endpoint",
        [
            'Content-Type'  => 'application/json',
            'Authorization' => "Bearer $api->{api_key}",
        ],
    );

    return $self->_http_send_request($api, $req);
}

sub _post {
    my ($self, $api) = @_;

    my $endpoint = $self->endpoint();
    my %params   = %{$self};

    my $req = HTTP::Request->new(
        POST => "$api->{api_base}/$endpoint",
        [
            'Content-Type'  => 'application/json',
            'Authorization' => "Bearer $api->{api_key}",
        ],
        encode_json( \%params ),
    );

    return $self->_http_send_request($api, $req);
}

sub _http_send_request {
    my ( $self, $api, $req ) = @_;

    for my $attempt ( 1 .. $api->{retry} ) {
        my $res = $api->user_agent->request($req);

        if ( $res->is_success ) {
            return decode_json( $res->decoded_content );
        } elsif ( $res->code =~ /^(?:500|503|504|599)$/ && $attempt < $api->{retry} ) {
            sleep( $api->{sleep} );
        } else {
            die "Error: '@{[ $res->status_line ]}'";
        }
    }
}

1;

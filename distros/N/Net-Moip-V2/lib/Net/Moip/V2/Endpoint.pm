package Net::Moip::V2::Endpoint;

use IO::Socket::SSL;
use MIME::Base64;
use Furl;
use JSON::MaybeXS ();

use Moo;

my $JSON = JSON::MaybeXS->new->utf8;

has 'path', is => 'ro', required => 1;

has 'api_url', is => 'ro',required => 1;

has 'ua', is => 'ro', required => 1;

has 'token', is => 'ro', required => 1;

has 'key', is => 'ro', required => 1;

has 'client_id', is => 'ro';

has 'client_secret', is => 'ro';

has 'access_token', is => 'ro';

has '_basic_auth_token', is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    'Basic '.MIME::Base64::encode_base64( $self->token .':'. $self->key, '');
};

has 'url', is => 'ro', init_arg => undef, default => sub {
    my $self = shift;
    join '/', $self->api_url, $self->path;
};

sub _authorization_string {
    my $self = shift;
    if ($self->{is_oauth}) {
        my $access_token = $self->access_token
            or die "Can't build OAuth authorization. access_token is missing.";

        return "OAuth $access_token";
    }

    $self->_basic_auth_token;
}


sub get {
    my ($self, $id) = @_;

    my $url = join '/', $self->url, $id || ();
    $self->ua->get($url, [
        'Content-Type'   => 'application/json',
        'Authorization' => $self->_authorization_string
    ]);
}

sub post {
    my ($self, $data) = @_;

    $self->ua->post($self->url, [

        'Content-Type'   => 'application/json',
        'Authorization' => $self->_authorization_string

    ], $JSON->encode($data) );
}

sub oauth_get {
    my $self = shift;
    local $self->{is_oauth} = 1;
    $self->get(@_);
}

sub oauth_post {
    my $self = shift;
    local $self->{is_oauth} = 1;
    $self->post(@_);
}


sub decode_json {
    my $self = shift;
    $JSON->decode($_[0]);
}



1;
__END__

=encoding utf-8

=head1 NAME

Net::Moip::V2::Endpoint - Send HTTP requests to an endpoint.

=head1 SYNOPSIS

    use Net::Moip::V2;

    my $moip = Net::Moip::V2->new( ... );

    # List orders: GET /orders
    my $ep_orders = $moip->endpoint('orders');
    my $response = $ep_orders->get;   # $response is a Furl::Response object


=head1 DESCRIPTION

This class represents a single endpoint in the Moip API v2. It provides methods
for sending raw http requests, handling the authorization and other required
http headers for you.

=head1 METHDOS

=head2 get[$id])

Sends a GET request to the endpoint L<url|/url>. Can optionally append the
a resource id to the url. Returns the raw L<Furl::Response> object.

    # GET https://api.moip.com.br/v2/orders
    my $response = $moip->endpoint('orders')->get;

    if ($response->is_success) {
        my $data = $moip->decode_json($response->content);
        foreach my $order (@{ $data->{orders} }) {
            ...
        }
    }

    # GET https://api.moip.com.br/v2/orders/ORD-123456789012
    my $response = $moip->endpoint('orders')->get('ORD-123456789012');

    if ($response->is_success) {
        my $order = $moip->decode_json($response->content);
        ...
    }

For detailed information about the response format, see https://dev.moip.com.br/v2.0/reference#intro.

=head2 post(\%data)

Sends a GET request to the endpoint L<url|/url>. The C<\%data> hashref is encoded
to JSON and the proper content type and authentication headers are set.
Returns the raw L<Furl::Response> object.

    # POST https://api.moip.com.br/v2/orders
    my $response = $moip->endpoint('orders')->post({
        ownId: '12345',
        amount: { ... },
        ...
    });

    if ($response->is_success) {
        my $new_order = $moip->decode_json($response->content);
        ...
    }

Consult the L<official API reference|https://dev.moip.com.br/v2.0/reference> for
detailed information about the required data for each endpoint.

=head2 decode_json($json_string)

Helper method for decoding json string into perl data.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut

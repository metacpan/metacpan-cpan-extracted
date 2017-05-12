package Net::Moip::V2;

use IO::Socket::SSL;
use MIME::Base64;
use Furl;
use JSON::MaybeXS ();
use Moo;
use URI;

use Net::Moip::V2::Endpoint;

our $VERSION = "0.06";

my $JSON = JSON::MaybeXS->new->utf8;

has 'ua', is => 'ro', default => sub {
    Furl->new(
        agent         => "Net-Moip-V2/$VERSION",
        timeout       => 15,
        max_redirects => 3,
        # <perigrin> "SSL Wants a read first" I think is suggesting you
        # haven't read OpenSSL a bedtime story in too long and perhaps
        # it's feeling neglected and lonely?
        # see also: https://metacpan.org/pod/IO::Socket::SSL#SNI-Support
        # https://metacpan.org/pod/Furl#FAQ
        # https://rt.cpan.org/Public/Bug/Display.html?id=86684
        ssl_opts => {
            SSL_verify_mode => SSL_VERIFY_PEER(),
            # forcing version yields better error message:
            SSL_version     => 'TLSv1_2',
        },
    );
};

has 'token', is => 'ro', required => 1;

has 'key', is => 'ro', required => 1;

has 'client_id', is => 'ro';

has 'client_secret', is => 'ro';

has 'access_token', is => 'rw';


has 'api_url', (
    is      => 'ro',
    writer  => '_set_api_url',
    default => 'https://api.moip.com.br/v2'
);

has 'oauth_url', (
    is      => 'ro',
    writer  => '_set_oauth_url',
    default => 'https://connect.moip.com.br'
);


has 'sandbox', (
    is      => 'rw',
    default => 0,
    trigger => sub {
        my ($self, $sandbox) = @_;
        $self->_set_api_url( $sandbox
            ? 'https://sandbox.moip.com.br/v2'
            : 'https://api.moip.com.br/v2'
        );
        $self->_set_oauth_url( $sandbox
            ? 'https://connect-sandbox.moip.com.br'
            : 'https://connect.moip.com.br'
        );
    }
);

has '_basic_auth_token', is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    'Basic '.MIME::Base64::encode_base64( $self->token .':'. $self->key, '');
};

sub build_authorization_url {
    my ($self, $redirect_uri, $scope) = @_;
    die 'Method signature is: build_authorization_url($redirect_uri, $scope)'
        unless $redirect_uri && $scope;

    my $url = URI->new($self->oauth_url.'/oauth/authorize');
    $url->query_form(
        response_type => 'code',
        client_id => $self->client_id,
        redirect_uri => $redirect_uri,
        scope => join(',', map { uc } @$scope)
    );
    $url;
}

sub request_access_token {
    my ($self, $redirect_uri, $code) = @_;
    die 'Method signature is: request_access_token($redirect_uri, $code)'
        unless $redirect_uri && $code;

    my $uri = URI->new($self->oauth_url.'/oauth/token');
    $uri->query_form(
        client_id => $self->client_id,
        client_secret => $self->client_secret,
        grant_type => 'authorization_code',
        redirect_uri => $redirect_uri,
        code => $code
    );

    my ($url, $body) = $uri->as_string =~ /(.*?)\?(.*)/;
    my $res = $self->ua->post($url, [
        'Content-Type'   => 'application/x-www-form-urlencoded',
        'Authorization' => $self->_basic_auth_token,
        'Cache-Control' => 'no-cache'
    ], $body);

    return { error => $res->status_line } if $res->code >= 500;
    $JSON->decode($res->content);
}




sub endpoint {
    my ($self, $path, $params) = @_;
    die "Syntax: moip->endpoint(<name>)" unless $path;
    Net::Moip::V2::Endpoint->new(
        (map { $_ => $self->$_ } qw/ ua api_url token key client_id client_secret access_token /),
        %{ $params ||  {} },
        path => $path,
    );
}

sub get {
    my $self = shift;
    my $endpoint = shift;
    $self->endpoint($endpoint)->get(@_);
}

sub post {
    my $self = shift;
    my $endpoint = shift;
    $self->endpoint($endpoint)->post(@_);
}


sub decode_json {
    my $self = shift;
    $JSON->decode($_[0]);
}




1;
__END__

=encoding utf-8

=head1 NAME

Net::Moip::V2 - Perl SDK for the Moip (Money over IP) v2 API.

=head1 SYNOPSIS

    use Net::Moip::V2;

    my $moip = Net::Moip::V2->new(
        token => '...',          # required
        key => '...',            # required
        client_id => '...',      # OAuth app id
        client_secret => '...',  # OAuth app secret
        access_token => '...',   # OAuth access token
    );

    # Working with the 'orders' endpoint
    my $ep_orders = $moip->endpoint('orders');

    # List orders: GET /orders
    my $response = $ep_orders->get;

    # Create new order: POST /orders
    my $new_order = $ep_orders->post(\%params);

    # Fetch order
    my $order = $ep_orders->get($new_order->{id});

    # Get order payments endpoint
    # GET /orders/<order id>/payments
    $response = $moip->endpoint("orders/$order->{id}/payments")->get;




=head1 DESCRIPTION

Net::Moip::V2 is a SDK for Moip (Money Over IP) V2 API. This version of the
module provides only a thin wrapper for the REST API, so you won't find methods
like C<create_order()> or C<get_orders()>. What this module will do is help you
build the endpoint paths, represented by L<Net::Moip::V2::Endpoint> objects and send
http requests, with authentication handled for you.

Higher level methods exists for requesting OAuth authorization and access token.
See L</build_authorization_url> and L</request_access_token>

Future versions can include a 'Client' class implementing a higher level of
abstraction like the methdos cited above. Pull requests are welcome! :)

For now, this 'wrapper' approach not only does the job, but also avoids me to
invent another API and you to learn it. All you have to do is follow the
L<official documentation|https://dev.moip.com.br/v2.0/reference>, build the
equivalent endpoint objects, and send your requests.

=head1 METHDOS

=head2 build_authorization_url($redirect_uri, \@scope) :Str $url

Builds the URL used to connect the user account to your Moip (OAuth) app. Usually
used in a web app controller to redirect the user's browser to the authorization
page.

C<$redirect_uri> is the URL the user will be redirected back to you app after
authorization.

C<\@scope> is the list of permssions you are asking authorization for.
See L<https://dev.moip.com.br/v2.0/reference#oauth-moip-connect> for the list of
valid permissions.

    # example of a Mojolicious controller redirecting the browser
    # to the "moip connect" page, where the user authorizes or declines the
    # permissions you requested
    sub moip_connect {
        my $c = shift;

        my $moip = Net::Moip::V2->new( ... );
        my $callback_url = $c->url_for('moip-callback'); #
        my $url = $moip->build_authorization_url(
            'http://myapp.com/moip-callback',
            ['RECEIVE_FUNDS', 'REFUND']
        );

        $c->redirect_to($url);
    }


=head2 request_access_token($redirect_uri, $code) :Hashref $response

After the user has allowed the permissions you requested via the authorization url,
his browser will be redirected back to your app, with the url parameter C<code>
containing the code you need to request the actual access token that you keep
for future requests on behalf of your user.

    # example of Mojolicious controller receiving the code after user
    # has authorized the permissions and connected his account to your app
    sub moip_callback {
        my $c = shift;

        my $moip = Net::Moip::V2->new( ... );
        my $code = $c->req->param('code');
        my $response = $moip->request_access_token(
            'http://myapp.com/moip-callback',       # must be the same passed to build_authorization_url()
            $code
        );

        if ($response->{error}) {
            # show error page and return
            ...
            return;
        }

        # all good, $response contains the information you need to associate
        # to the user account in you app: access token, moip account id,
        # refresh token and token expiration date
        ...
    }

=head2 endpoint($path)

Returns a new endpoint object for sending requests to $path.

    my $orders_ep = $moip->endpoint('orders');
    my $single_order_payments_ep = $moip->endpoint("orders/ORD-123456789012/payments");

See L<Net::Moip::V2::Endpoint>.

=head2 get($endpoint [, @args])

Shortcut for C<< $moip->endpoint('foo')->get(@args) >>.

=head2 post($endpoint [, @args])

Shortcut for C<< $moip->endpoint('foo')->post(@args) >>.

=head1 ACKNOWLEDGMENTS

The development of this software is supported by the brazilian startup
L<Zoom Dentistas|http://www.zoomdentistas.com.br>.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut

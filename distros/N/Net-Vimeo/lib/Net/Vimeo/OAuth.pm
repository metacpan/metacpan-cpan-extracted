package Net::Vimeo::OAuth;

use Carp;
use Digest::SHA;

use HTTP::Request;
use HTTP::Request::Common;

use LWP::UserAgent;

use Moose::Role;

use Types::Standard qw( InstanceOf );

use URI;
use URI::Escape;

use namespace::autoclean;

use Net::OAuth;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);
    my $oauth_urls = {
        request_token_url  => "https://vimeo.com/oauth/request_token",
        authorization_url  => "https://vimeo.com/oauth/authorize",
        access_token_url   => "https://vimeo.com/oauth/access_token",
        xauth_url          => "https://vimeo.com/oauth/access_token",
    };

    return { %$oauth_urls, %$args };
};

has [ qw( consumer_key consumer_secret ) ] => ( is => 'ro', isa => 'Str', required => 1 );

has 'user_agent' => (
    is      => 'ro',
    isa     => InstanceOf['LWP::UserAgent'],
    lazy    => 1,
    builder => '_build_user_agent',
);

# Oauth URL attributes
for my $attribute ( qw/authorization_url request_token_url access_token_url/ ) {
    has $attribute => (
        is       => 'rw', 
        isa      => 'Str', 
        required => 1,
        reader   => { $attribute => sub { URI->new(shift->{$attribute}) } },
    );
}

for my $attribute ( qw/access_token access_token_secret request_token request_token_secret/ ) {
    has $attribute => ( 
        is          => 'rw', 
        isa         => 'Str',
        clearer     => "clear_$attribute",
        predicate   => "has_$attribute",
    );
}

sub _build_user_agent {
    my $self       = shift;
    my $user_agent = LWP::UserAgent->new();

    $user_agent->env_proxy;

    return $user_agent;
}


sub get_authorization_url {
    my ( $self, %params ) = @_;

    my $callback = delete $params{callback} || 'oob';
    $self->authorization_request_token(callback => $callback);

    my $uri = $self->authorization_url;
    $uri->query_form(oauth_token => $self->request_token,  %params);

    return $uri;
}

sub make_oauth_request {
    my ( $self, $type, %params ) = @_;

    return unless $type;

    my $proto = Net::OAuth->request($type);

    my $request = $proto->new(
        version             => '1.0',
        consumer_key        => $self->consumer_key,
        consumer_secret     => $self->consumer_secret,
        request_method      => 'GET',
        signature_method    => 'HMAC-SHA1',
        timestamp           => time,
        nonce               => Digest::SHA::sha1_base64(time . $$ . rand),
        %params,
    );

    $request->sign;

    return $request;
}

sub get_request_token {
    my ( $self, $params ) = @_;

    my $uri = $self->request_token_url;

    my $request = $self->make_oauth_request(
        'request token',
        request_url => $uri,
        %$params,
    );

    my $http_req = HTTP::Request->new( GET => $uri );
    $http_req->headers->authorization_basic( $self->consumer_key, $self->consumer_secret );
    $http_req->header(authorization => $request->to_authorization_header);

    my $res = $self->user_agent->send_request($http_req);

    if ( $res->is_success ) {
        $uri->query($res->content);
        my %res_params = $uri->query_form;

        return (
            $self->request_token($res_params{oauth_token}),
            $self->request_token_secret($res_params{oauth_token_secret}),
        );
    } else {
        croak sprintf( "Something went wrong on GET %s: %s", $uri, $res->status_line );
    }
}

sub get_access_token {
    my ( $self, $params ) = @_;

    my $uri = $self->access_token_url;

    my $request = $self->make_oauth_request(
        'access token',
        request_url  => $uri,
        token        => $self->request_token,
        token_secret => $self->request_token_secret, 
        %$params,
    );

    my $http_req = HTTP::Request->new( GET => $uri );
    $http_req->header(authorization => $request->to_authorization_header);

    my $res = $self->user_agent->send_request( $http_req );

    if ( $res->is_success ) {
        my $response = Net::OAuth->response('access token')->from_post_body($res->content);
        $self->clear_request_token;
        $self->clear_request_token_secret;

        $uri->query($res->content);
        my %res_params = $uri->query_form;

        return (
            $self->access_token($res_params{oauth_token}),
            $self->access_token_secret($res_params{oauth_token_secret}),
        );

    } else {
        croak sprintf( "Something went wrong on GET %s: %s", $uri, $res->status_line )
    }
}

# Need the request tokens so that later we
# exchage them with access tokens
sub authorization_request_token {
    my ($self, %params) = @_;

    my $uri = $self->request_token_url;
    my $request = $self->make_oauth_request(
        'request token',
        request_url => $uri,
        %params,
    );

    my $msg = HTTP::Request->new(GET => $uri);
    $msg->header(authorization => $request->to_authorization_header);

    my $res = $self->user_agent->send_request($msg);

    if ( $res->is_success ) {
        $uri->query($res->content);
        my %res_param = $uri->query_form;

        $self->request_token($res_param{oauth_token});
        $self->request_token_secret($res_param{oauth_token_secret});
    } else {
        croak sprintf( "Something went wrong on GET %s: %s", $uri, $res->status_line )
    }
}

1;

__END__

=head1 NAME

Net::Vimeo::OAuth - OAuth for Vimeo Advanced API

=head1 DESCRIPTION

Net::Vimeo::OAuth is a role that provides OAuth
authentication for Vimeo Advanced API.

=head1 SYNOPSIS

    # First you need to authorize user to access data:
    my $vimeo = Net::Vimeo->new(
        consumer_key    => 'your_app_key',
        consumer_secret => 'your_app_secret_key',
    );

    # To get access tokens you need the oauth_verifier,
    # request_token and request_token secret. The last two 
    # were obtain when you got the authorization url. Vimeo
    # redirects user to application, passing the oauth_verifier

    # The oauth_verifier will be obtain after you give access 
    # to your application. 

    my $auth_url =  $vimeo_oauth->get_authorization_url();
    my $verifier = 'oauth_verifier_code';

    $vimeo_oauth->get_access_token( { verifier => $verifier } );

    # Now you have your access tokens and do not need to go through
    # this process every time you make an api request
    print "Access token: " . $self->access_token . "\n";
    print "Accesss token secret: " . $self->access_token_secret . "\n";

=head1 DESCRIPTION

Net::Vimeo::OAuth is a perl interface to Vimeo Advanced API
    
=head1 METHODS

=over 4

=item get_authorization_url

Get the URL needed to authorzie the user. It returns an C<URI> object. 
When you get this URL it will be generated a request token and a request 
token secret that will be used later to get access tokens.

=item get_request_token

Get request tokens that later can be exchanged with access tokens.

=item get_access_token

In order to use Vimeo Advanced API you will need access tokens. This is 
the final step in authorizing you app. Given the request tokens and the oauth verifier
from C<get_authorization_url> you can exchange it with access tokens.

An access_token is the key you get from a user which allows your app to
act on behalf of a user. Usually your application will collect an acceess_token
by sending the user to a callback, an URL where the user can decide if she
grants access or not. Vimeo provides a readily available access_token
for your own account on your private developer page where you register your
app.

=item access_token

Set the acceee_token with this method. (provided via L<Net::OAuth>)

=item access_token_secret

Set the acceee_token_secret with this method. (provided via L<Net::OAuth>)

=back

=head1 SEE ALSO

L<Net::Vimeo>

=head1 AUTHOR

Mirela Iclodean, C<< <imirela at cpan.org> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


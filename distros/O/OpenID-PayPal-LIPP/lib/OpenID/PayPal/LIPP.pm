package OpenID::PayPal::LIPP;

use strict;
use 5.008_005;
use warnings;
our $VERSION = '0.02';

use Carp;
use JSON;
use URI;
use URI::QueryParam;
use HTTP::Request::Common;
use Convert::Base64;
use LWP::UserAgent;
use Moo;
use namespace::clean;

has client_id                           => ( is => 'ro', required => 1 );
has client_secret                       => ( is => 'ro', required => 1 );
has account                             => ( is => 'ro', required => 1 );
has redirect_uri                        => ( is => 'ro', required => 1 );
has mode                                => ( is => 'ro', default => sub { 'sandbox' }, isa => sub { die 'Must be live or sandbox' unless $_[0] =~ m/^live$|^sandbox$/; } );
has scope                               => ( is => 'ro', default => sub { [ qw(openid email) ]; } );
has paypal_openid_endpoint              => ( is => 'lazy' );
has paypal_auth_token_service_endpoint  => ( is => 'lazy' );
has paypal_auth_user_profile_end_point  => ( is => 'lazy' );
has logger                              => ( is => 'ro', default => sub{ sub{}; }, isa => sub { die 'Logger has to be a function' unless ref $_[0] eq 'CODE' } );

sub _log {
    my $self = shift;
    if( defined $self->logger ) {
        $self->logger->( @_ );
    }
}

sub _build_paypal_openid_endpoint {
    my $self = shift;

    if( $self->mode eq 'live' ) {
        return 'https://www.paypal.com/webapps/auth/protocol/openidconnect/v1/authorize';
    } else {
        return 'https://www.sandbox.paypal.com/webapps/auth/protocol/openidconnect/v1/authorize';
    }
}

sub _build_paypal_auth_token_service_endpoint {
    my $self = shift;

    if( $self->mode eq 'live' ) {
        return 'https://api.paypal.com/v1/identity/openidconnect/tokenservice';
    } else {
        return 'https://api.sandbox.paypal.com/v1/identity/openidconnect/tokenservice';
    }
}

sub _build_paypal_auth_user_profile_end_point {
    my $self = shift;

    if( $self->mode eq 'live' ) {
        return 'https://api.paypal.com/v1/identity/openidconnect/userinfo';
    } else {
        return 'https://api.sandbox.paypal.com/v1/identity/openidconnect/userinfo';
    }
}

sub login_url {
    my $self = shift;
    my $state = shift;

    my $login_url = URI->new( $self->paypal_openid_endpoint );
    $login_url->query_param( client_id => $self->client_id );
    $login_url->query_param( response_type => 'code' );
    $login_url->query_param( scope => join( ' ', @{$self->scope}) );
    $login_url->query_param( redirect_uri => $self->redirect_uri );
    $login_url->query_param( state => $state )
        if defined $state;

    $self->_log( "Login url is : ".$login_url->as_string );

    return $login_url->as_string;
}

sub exchange_code {
    my ($self, $code) = @_;

	my $post_data = {
		grant_type => 'authorization_code',
		code => $code,
        redirect_uri => $self->redirect_uri,
	};

    my $encoded_header = encode_base64($self->client_id . ":" . $self->client_secret );
	my $data_json = $self->_post(
        $self->paypal_auth_token_service_endpoint,
        $post_data,
        { Authorization => "Basic $encoded_header" }
    );
	my $data_hash = decode_json($data_json);

    return {
        access_token    => $data_hash->{access_token},
        refresh_token   => $data_hash->{refresh_token},
    };
}

sub refresh_token {
    my ($self, $refresh_token) = @_;

	my $post_data = {
		grant_type => 'refresh_token',
		refresh_token => $refresh_token,
        scope => join( ' ', @{$self->scope}),
	};

    my $encoded_header = encode_base64($self->client_id . ":" . $self->client_secret );
	my $data_json = $self->_post(
        $self->paypal_auth_token_service_endpoint,
        $post_data,
        { Authorization => "Basic $encoded_header" }
    );
	my $data_hash = decode_json($data_json);

    return {
        access_token    => $data_hash->{access_token},
        refresh_token   => $refresh_token,
    };
}

sub get_user_details {
	my ( $self, %params ) = @_;

    my $token = undef;
    if( exists $params{authorization_code} ) {
        $token = $self->exchange_code( $params{authorization_code} )->{access_token};
    } elsif( exists $params{access_token} ) {
        $token = $params{access_token};
    } else {
        croak "Provide authorization code or access token";
    }

	my $post_params = {
		schema => "openid",
		access_token => $token,
	};

	my $customer_data_json = $self->_get( $self->paypal_auth_user_profile_end_point, $post_params );
	my $customer_data_hash = decode_json( $customer_data_json );

	return $customer_data_hash;
}

sub _user_agent {
    return LWP::UserAgent->new();
}

sub _post
{
	my ( $self, $url, $post, $headers ) = @_;

	my $request = HTTP::Request::Common::POST( $url, Content => [ %$post ]);
    if( defined $headers ) {
        while( my ($header, $value) = each %$headers ) {
            $request->header( $header => $value );
        }
    }

	my $response = $self->_user_agent->request( $request );

	if ( $response->is_error )
	{
        $self->_log( "Post request failed, url : " . $url . " , parameters: " );
        while( my ($key, $value) = each %$post ) {
            $self->_log( "$key => $value" );
        }
		croak "Error calling PayPal, PayPal Response : " . $response->content;
	}

	return $response->content;
}


sub _get
{
	my ( $self, $url, $params ) = @_;

    my $uri = URI->new( $url );

    if( defined $params ) {
        while( my ($param, $value)  = each %$params ) {
            $uri->query_param( $param => $value );
        }
    }

	my $request = HTTP::Request->new( 'GET', $uri->as_string );

	my $response = $self->_user_agent->request( $request );
	if ( $response->is_error )
	{
        $self->_log( "Get request failed, url : " . $uri->as_string );
		croak "Error calling PayPal, PayPal Response : " . $response->content;
	}

	return $response->content;
}

no Moo;
1;
__END__

=encoding utf-8

=head1 NAME

OpenID::PayPal::LIPP - Login with PayPal

=head1 SYNOPSIS

    use OpenID::PayPal::LIPP;

    my $lipp = OpenID::PayPal::LIPP->new(
        client_id => 'CLIENT_ID',
        client_secret => 'CLIENT_SECRET',
        account => 'ACCOUNT',
        mode => 'sandbox',
        redirect_uri => 'http://localhost/callback',
    );

    my $url = $lipp->login_url();

    # user after visiting that url, user will be redirected to http://localhost/callback with a parameter code
    # you can either directly the user info with the code, or exchange code for access token

    my $token = $pp->exchange_code( $code );

    #$token contain an access token and a refresh token
    #to get a new access token from refresh token :
    $token = $pp->refresh_token( $token->{refresh_token} );

    #to get user info, you can either give access_token, or authorization code
    my $user_info = $pp->get_user_details( access_token => $token->{access_token} );
    my $user_info = $pp->get_user_details( authorization_code => $code );

    print $user_info->email

=head1 DESCRIPTION

OpenID::PayPal::LIPP is a simple implementation for the Login with PayPayl API.

=head2 METHODS

Following methods are available

=head3 new( options )

Constructor take the following required arguments:

=over

=item * client_id: client id of your paypal application

=item * client_secret: client secret of your paypal application

=item * account: account linked to your paypal application

=item * redirect_uri: redirection url registered in your paypal application, user will be redirected there after login in PayPal website

=item * mode: sandbox or live

=back

You have some more control with the following optionnal argument:

=over

=item * scope: arrayref of the scope you want to get access to, default is [ 'openid', 'email' ]

=item * logger: coderef to a sub used to log some internal debug messages, see logger section

=back

=head3 login_url( state ), state is optional

Return login url to redirect the user to, state if provided will be passed to paypal, and return to your callback url

=head3 exchange_code( $code, [ $state ] )

Exchange authorization code for token, token is a hash of 2 keys, access_token and refresh_token.

=head3 refresh_token( $refresh_token )

Allow you to refresh your access token from your refresh token, it will return a hash of 2 keys, access_token and refresh_token.

=head3 get_user_details( authorization_code => $code, access_token => $access_token )

Call that method with either the authorization code or an access token to get paypal's user info, in a hash

=head2 LOGGER

In case there is an issue on paypal side, the module with croak, so you should use it in an eval block, or better with Try::Tiny
To get some more info, you can pass a sub to the constructor in field logger. That sub will get called with debug message within the process
of calling paypal.

    my $lipp = OpenID::PayPal::LIPP->new(
        client_id => 'CLIENT_ID',
        client_secret => 'CLIENT_SECRET',
        account => 'ACCOUNT',
        mode => 'sandbox',
        redirect_uri => 'http://localhost/callback',
        logger => sub { warn @_ }
    );

=head1 AUTHOR

Pierre VIGIER E<lt>pierre.vigier@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Pierre VIGIER

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

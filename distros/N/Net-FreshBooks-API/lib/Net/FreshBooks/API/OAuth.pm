use strict;
use warnings;

package Net::FreshBooks::API::OAuth;
$Net::FreshBooks::API::OAuth::VERSION = '0.24';
use base qw(Net::OAuth::Simple);

use Carp qw( croak );
use Data::Dump qw( dump );
use Params::Validate qw(:all);

sub new {

    my $class  = shift;
    my %tokens = @_;

    foreach my $key ( 'consumer_secret', 'consumer_key', 'account_name' ) {
        if ( !exists $tokens{$key} || !$tokens{$key} ) {
            croak( "$key required as an argument to new()" );
        }
    }

    my $account_name = delete $tokens{account_name};

    my $url = 'https://' . $account_name . '.freshbooks.com/oauth';

    my %create = (
        tokens           => \%tokens,
        protocol_version => '1.0a',
        urls             => {
            authorization_url => $url . '/oauth_authorize.php',
            request_token_url => $url . '/oauth_request.php',
            access_token_url  => $url . '/oauth_access.php',
        },
        signature_method => 'PLAINTEXT',
    );

    return $class->SUPER::new( %create );

}

sub restricted_request {

    my $self    = shift;
    my $url     = shift;
    my $content = shift;

    if ( !$self->authorized ) {
        return $self->_error( "This restricted request is not authorized" );
    }

    my %request = (
        consumer_key     => $self->consumer_key,
        consumer_secret  => $self->consumer_secret,
        request_url      => $url,
        request_method   => 'POST',
        signature_method => $self->signature_method,
        protocol_version => Net::OAuth::PROTOCOL_VERSION_1_0A,
        timestamp        => time,
        nonce            => $self->_nonce,
        token            => $self->access_token,
        token_secret     => $self->access_token_secret,
    );

    my $request = Net::OAuth::ProtectedResourceRequest->new( %request );

    $request->sign;

    if ( !$request->verify ) {
        return $self->_error(
            "Couldn't verify request! Check OAuth parameters." );
    }

    my $params      = $request->to_hash;
    my @auth_header = ();

    # building the header here because the Net::OAuth::Simple stuff wasn't
    # authenticating
    foreach my $key ( keys %{ $request->to_hash } ) {
        my $name = $key;
        $name =~ s{-}{_}g;
        push @auth_header, sprintf( '%s="%s"', $name, $params->{$key} );
    }

    my $auth = 'OAuth realm="",' . join ",", @auth_header;
    my $headers = HTTP::Headers->new( Authorization => $auth );

    my $req = HTTP::Request->new( 'POST' => $url, $headers, $content );

    my $response = $self->{browser}->request( $req );

    if ( !$response->is_success ) {
        return $self->_error( "POST on "
                . $request->normalized_request_url
                . " failed: "
                . $response->status_line . " - "
                . $response->content );
    }

    return $response;
}

##############################################################################
# the following methods can be deleted once a patched version of
# Net::OAuth::Simple has been released

sub request_access_token {
    my $self   = shift;
    my %params = @_;
    my $url    = $self->access_token_url;

    $params{token} = $self->request_token unless defined $params{token};
    $params{token_secret} = $self->request_token_secret
        unless defined $params{token_secret};

    if ( $self->oauth_1_0a ) {
        $params{verifier} = $self->verifier unless defined $params{verifier};
        return $self->_error(
            "You must pass a verified parameter when using OAuth v1.0a" )
            unless defined $params{verifier};

    }

    my $access_token_response
        = $self->_make_request( 'Net::OAuth::AccessTokenRequest',
        $url, 'POST', %params, );

    return $self->_decode_tokens( $url, $access_token_response );
}

sub request_request_token {
    my $self   = shift;
    my %params = @_;
    my $url    = $self->request_token_url;

    if ( $self->oauth_1_0a ) {
        $params{callback} = $self->callback unless defined $params{callback};
        return $self->_error(
            "You must pass a callback parameter when using OAuth v1.0a" )
            unless defined $params{callback};
    }

    my $request_token_response
        = $self->_make_request( 'Net::OAuth::RequestTokenRequest',
        $url, 'POST', %params );

    return $self->_error(
        "GET for $url failed: " . $request_token_response->status_line )
        unless ( $request_token_response->is_success );

    # Cast response into CGI query for EZ parameter decoding
    my $request_token_response_query
        = new CGI( $request_token_response->content );

    # Split out token and secret parameters from the request token response
    $self->request_token(
        $request_token_response_query->param( 'oauth_token' ) );
    $self->request_token_secret(
        $request_token_response_query->param( 'oauth_token_secret' ) );
    $self->callback_confirmed(
        $request_token_response_query->param( 'oauth_callback_confirmed' ) );

    return $self->_error(
        "Response does not confirm to OAuth1.0a. oauth_callback_confirmed not received"
    ) if $self->oauth_1_0a && !$self->callback_confirmed;

}

sub _make_request {
    my $self   = shift;
    my $class  = shift;
    my $url    = shift;
    my $method = uc( shift );
    my @extra  = @_;

    my $uri   = URI->new( $url );
    my %query = $uri->query_form;
    $uri->query_form( {} );

    my $request = $class->new(
        consumer_key     => $self->consumer_key,
        consumer_secret  => $self->consumer_secret,
        request_url      => $uri,
        request_method   => $method,
        signature_method => $self->signature_method,
        protocol_version => $self->oauth_1_0a
        ? Net::OAuth::PROTOCOL_VERSION_1_0A
        : Net::OAuth::PROTOCOL_VERSION_1_0,
        timestamp    => time,
        nonce        => $self->_nonce,
        extra_params => \%query,
        @extra,
    );
    $request->sign;
    return $self->_error( "Couldn't verify request! Check OAuth parameters." )
        unless $request->verify;

    my $params = $request->to_hash;
    $uri->query_form( %$params );
    my $req = HTTP::Request->new( $method => "$uri" );
    my $response = $self->{browser}->request( $req );
    return $self->_error( "$method on "
            . $request->normalized_request_url
            . " failed: "
            . $response->status_line . " - "
            . $response->content )
        unless ( $response->is_success );

    return $response;
}

# ABSTRACT: FreshBooks OAuth implementation


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::OAuth - FreshBooks OAuth implementation

=head1 VERSION

version 0.24

=head2 DESCRIPTION

This package subclasses Net::OAuth::Simple, which is itself a wrapper around
L<Net::OAuth> You shouldn't need to deal with this class directly, but it's
available to you if you need it. Any of the methods which
L<Net::OAuth::Simple> uses are available to you. This subclass only overrides
the new() method.

=head2 SYNOPSIS

    # these params are required
    my $oauth = Net::FreshBooks::API::OAuth->new(
        consumer_key        => $consumer_key,
        consumer_secret     => $consumer_secret,
        account_name        => $account_name,
    );

    # if you already have your access_token and access_token_secret:
    my $oauth = Net::FreshBooks::API::OAuth->new(
        consumer_key        => $consumer_key,
        consumer_secret     => $consumer_secret,
        access_tokey        => $access_token,
        access_token_secret => $access_token_secret,
        account_name        => $account_name,
    );

=head2 new()

consumer_key, consumer_key_secret and account_name are all required params:

    my $oauth = Net::FreshBooks::API::OAuth->new(
        consumer_key        => $consumer_key,
        consumer_secret     => $consumer_secret,
        account_name        => $account_name,
    );

If you have already gotten your access tokens, you may create a new object
with them as well:

    my $oauth = Net::FreshBooks::API::OAuth->new(
        consumer_key        => $consumer_key,
        consumer_secret     => $consumer_secret,
        access_token        => $access_token,
        access_token_secret => $access_token_secret,
        account_name        => $account_name,
    );

=head2 restricted_request( $url, $content )

If you have provided your consumer and access tokens, you should be able to
make restricted requests.

    my $request = $oauth->restricted_request( $api_url, $xml )

Returns an HTTP::Response object

=head1 AUTHORS

=over 4

=item *

Edmund von der Burg <evdb@ecclestoad.co.uk>

=item *

Olaf Alders <olaf@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edmund von der Burg & Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

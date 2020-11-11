package Net::OAuth2::AuthorizationServer;

=head1 NAME

Net::OAuth2::AuthorizationServer - Easier implementation of an OAuth2
Authorization Server

=for html
<a href='https://travis-ci.org/Humanstate/net-oauth2-authorizationserver?branch=master'><img src='https://travis-ci.org/Humanstate/net-oauth2-authorizationserver.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/github/Humanstate/net-oauth2-authorizationserver?branch=master'><img src='https://coveralls.io/repos/github/Humanstate/net-oauth2-authorizationserver/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

0.28

=head1 SYNOPSIS

    my $Server = Net::OAuth2::AuthorizationServer->new;

    my $Grant  = $Server->$grant_type(
        ...
    );

=head1 DESCRIPTION

This module is the gateway to the various OAuth2 grant flows, as documented
at L<https://tools.ietf.org/html/rfc6749>. Each module implements a specific
grant flow and is designed to "just work" with minimal detail and effort.

Please see L<Net::OAuth2::AuthorizationServer::Manual> for more information
on how to use this module and the various grant types. You should use the manual
in conjunction with the grant type module you are using to understand how to
override the defaults if the "just work" mode isn't good enough for you.

=cut

use strict;
use warnings;

use Moo;
use Types::Standard qw/ :all /;

use Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant;
use Net::OAuth2::AuthorizationServer::ImplicitGrant;
use Net::OAuth2::AuthorizationServer::PasswordGrant;
use Net::OAuth2::AuthorizationServer::ClientCredentialsGrant;

our $VERSION = '0.28';

=head1 GRANT TYPES

=head2 auth_code_grant

OAuth Authorisation Code Grant as document at L<http://tools.ietf.org/html/rfc6749#section-4.1>.

See L<Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant>.

=cut

sub auth_code_grant {
    my ( $self, @args ) = @_;
    return Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant->new( @args );
}

=head2 implicit_grant

OAuth Implicit Grant as document at L<https://tools.ietf.org/html/rfc6749#section-4.2>.

See L<Net::OAuth2::AuthorizationServer::ImplicitGrant>.

=cut

sub implicit_grant {
    my ( $self, @args ) = @_;
    return Net::OAuth2::AuthorizationServer::ImplicitGrant->new( @args );
}

=head2 password_grant

OAuth Resource Owner Password Grant as document at L<http://tools.ietf.org/html/rfc6749#section-4.3>.

See L<Net::OAuth2::AuthorizationServer::PasswordGrant>.

=cut

sub password_grant {
    my ( $self, @args ) = @_;
    return Net::OAuth2::AuthorizationServer::PasswordGrant->new( @args );
}

=head2 client_credentials_grant

OAuth Client Credentials Grant as document at L<http://tools.ietf.org/html/rfc6749#section-4.4>.

See L<Net::OAuth2::AuthorizationServer::ClientCredentialsGrant>.

=cut

sub client_credentials_grant {
    my ( $self, @args ) = @_;
    return Net::OAuth2::AuthorizationServer::ClientCredentialsGrant->new( @args );
}

=head1 SEE ALSO

L<Mojolicious::Plugin::OAuth2::Server> - A Mojolicious plugin using this module

L<Crypt::JWT> - encode/decode JWTs

=head1 AUTHOR & CONTRIBUTORS

Lee Johnson - C<leejo@cpan.org>

With contributions from:

Martin Renvoize - C<martin.renvoize@ptfs-europe.com>

Pierre VIGIER - C<pierre.vigier@gmail.com>

Ian Sillitoe - L<https://github.com/sillitoe>

Mirko Tietgen - L<mirko@abunchofthings.net>

Dylan William Hardison - L<dylan@hardison.net>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

    https://github.com/Humanstate/net-oauth2-authorizationserver

=cut

__PACKAGE__->meta->make_immutable;

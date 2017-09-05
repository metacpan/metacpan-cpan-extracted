# NAME

Net::OAuth2::AuthorizationServer - Easier implementation of an OAuth2
Authorization Server

<div>

    <a href='https://travis-ci.org/Humanstate/net-oauth2-authorizationserver?branch=master'><img src='https://travis-ci.org/Humanstate/net-oauth2-authorizationserver.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/github/Humanstate/net-oauth2-authorizationserver?branch=master'><img src='https://coveralls.io/repos/github/Humanstate/net-oauth2-authorizationserver/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

# VERSION

0.16

# SYNOPSIS

    my $Server = Net::OAuth2::AuthorizationServer->new;

    my $Grant  = $Server->$grant_type(
        ...
    );

# DESCRIPTION

This module is the gateway to the various OAuth2 grant flows, as documented
at [https://tools.ietf.org/html/rfc6749](https://tools.ietf.org/html/rfc6749). Each module implements a specific
grant flow and is designed to "just work" with minimal detail and effort.

Please see [Net::OAuth2::AuthorizationServer::Manual](https://metacpan.org/pod/Net::OAuth2::AuthorizationServer::Manual) for more information
on how to use this module and the various grant types. You should use the manual
in conjunction with the grant type module you are using to understand how to
override the defaults if the "just work" mode isn't good enough for you.

# GRANT TYPES

## auth\_code\_grant

OAuth Authorisation Code Grant as document at [http://tools.ietf.org/html/rfc6749#section-4.1](http://tools.ietf.org/html/rfc6749#section-4.1).

See [Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant](https://metacpan.org/pod/Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant).

## implicit\_grant

OAuth Implicit Grant as document at [https://tools.ietf.org/html/rfc6749#section-4.2](https://tools.ietf.org/html/rfc6749#section-4.2).

See [Net::OAuth2::AuthorizationServer::ImplicitGrant](https://metacpan.org/pod/Net::OAuth2::AuthorizationServer::ImplicitGrant).

## password\_grant

OAuth Resource Owner Password Grant as document at [http://tools.ietf.org/html/rfc6749#section-4.3](http://tools.ietf.org/html/rfc6749#section-4.3).

See [Net::OAuth2::AuthorizationServer::PasswordGrant](https://metacpan.org/pod/Net::OAuth2::AuthorizationServer::PasswordGrant).

## client\_credentials\_grant

OAuth Client Credentials Grant as document at [http://tools.ietf.org/html/rfc6749#section-4.4](http://tools.ietf.org/html/rfc6749#section-4.4).

See [Net::OAuth2::AuthorizationServer::ClientCredentialsGrant](https://metacpan.org/pod/Net::OAuth2::AuthorizationServer::ClientCredentialsGrant).

# SEE ALSO

[Mojolicious::Plugin::OAuth2::Server](https://metacpan.org/pod/Mojolicious::Plugin::OAuth2::Server) - A Mojolicious plugin using this module

[Mojo::JWT](https://metacpan.org/pod/Mojo::JWT) - encode/decode JWTs

# AUTHOR & CONTRIBUTORS

Lee Johnson - `leejo@cpan.org`

With contributions from:

Martin Renvoize - `martin.renvoize@ptfs-europe.com`

Pierre VIGIER `pierre.vigier@gmail.com`

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

    https://github.com/Humanstate/net-oauth2-authorizationserver

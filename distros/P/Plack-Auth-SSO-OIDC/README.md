# NAME

Plack::Auth::SSO::OIDC - implementation of OpenID Connect for Plack::Auth::SSO

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Plack-Auth-SSO-OIDC.svg?branch=main)](https://travis-ci.org/LibreCat/Plack-Auth-SSO-OIDC)
[![Coverage](https://coveralls.io/repos/LibreCat/Plack-Auth-SSO-OIDC/badge.png?branch=main)](https://coveralls.io/r/LibreCat/Plack-Auth-SSO-OIDC)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Plack-Auth-SSO-OIDC.png)](http://cpants.cpanauthors.org/dist/Plack-Auth-SSO-OIDC)

# DESCRIPTION

This is an implementation of [Plack::Auth::SSO](https://metacpan.org/pod/Plack%3A%3AAuth%3A%3ASSO) to authenticate against a openid connect server.

It inherits all configuration options from its parent.

# SYNOPSIS

    # in your app.psi (Plack)

    use strict;
    use warnings;
    use Plack::Builder;
    use JSON;
    use Plack::Auth::SSO::OIDC;
    use Plack::Session::Store::File;

    my $uri_base = "http://localhost:5000";

    builder {

        # session middleware needed to store "auth_sso" and/or "auth_sso_error"
        # in memory session store for testing purposes
        enable "Session";

        # for authentication, redirect your users to this path
        mount "/auth/oidc" => Plack::Auth::SSO::OIDC->new(

            # plack application needs to know about the base url of this application
            uri_base => $uri_base,

            # after successfull authentication, user is redirected to this path (uri_base is used!)
            authorization_path => "/auth/callback",

            # when authentication fails at the identity provider
            # user is redirected to this path with session key "auth_sso_error" (hash)
            error_path => "/auth/error",

            # openid connect discovery url
            openid_uri => "https://example.oidc.org/auth/oidc/.well-known/openid-configuration",
            client_id => "my-client-id",
            client_secret => "myclient-secret",
            uid_key => "email"

        )->to_app();

        # example psgi app that is called after successfull authentication at /auth/oidc (see above)
        # it expects session key "auth_sso" to be present
        # here you typically create a user session based on the uid in "auth_sso"
        mount "/auth/callback" => sub {

            my $env     = shift;
            my $session = Plack::Session->new($env);
            my $auth_sso= $session->get("auth_sso");
            my $user    = MyUsers->get( $auth_sso->{uid} );
            $session->set("user_id", $user->{id});
            [ 200, [ "Content-Type" => "text/plain" ], [
                "logged in! ", $user->{name}
            ]];

        };

        # example psgi app that is called after unsuccessfull authentication at /auth/oidc (see above)
        # it expects session key "auth_sso_error" to be present
        mount "/auth/error" => sub {

            my $env = shift;
            my $session = Plack::Session->new($env);
            my $auth_sso_error = $session->get("auth_sso_error");

            [ 200, [ "Content-Type" => "text/plain" ], [
                "something happened during single sign on authentication: ",
                $auth_sso_error->{content}
            ]];

        };
    };

# CONSTRUCTOR ARGUMENTS

- `uri_base`

    See ["uri\_base" in Plack::Auth::SSO](https://metacpan.org/pod/Plack%3A%3AAuth%3A%3ASSO#uri_base)

- `id`

    See ["id" in Plack::Auth::SSO](https://metacpan.org/pod/Plack%3A%3AAuth%3A%3ASSO#id)

- `session_key`

    See ["session\_key" in Plack::Auth::SSO](https://metacpan.org/pod/Plack%3A%3AAuth%3A%3ASSO#session_key)

- `authorization_path`

    See ["authorization\_path" in Plack::Auth::SSO](https://metacpan.org/pod/Plack%3A%3AAuth%3A%3ASSO#authorization_path)

- `error_path`

    See ["error\_path" in Plack::Auth::SSO](https://metacpan.org/pod/Plack%3A%3AAuth%3A%3ASSO#error_path)

- `openid_uri`

    base url of the OIDC discovery url.

    typically an url that ends on `/.well-known/openid-configuration`

- `client_id`

    client-id as given by the OIDC service

- `client_secret`

    client-secret as given by the OIDC service

- `scope`

    Scope requested from the OIDC service.

    Space separated string containing all scopes

    Default: `"openid profile email"`

    Please include scope `"openid"`

    cf. [https://openid.net/specs/openid-connect-basic-1\_0.html#Scopes](https://openid.net/specs/openid-connect-basic-1_0.html#Scopes)

- `authorize_params`

    Hash reference of parameters (values must be strings) that are added to

    the authorization url. Empty by default

    e.g. `{ prompt => "login", "kc_idp_hint" => "orcid" }`

    Note that some parameters are set internally

    and therefore will have no effect:

    - `code_challenge`
    - `code_challenge_method`
    - `state`
    - `scope`
    - `client_id`
    - `response_type`
    - `redirect_uri`

- `allowed_authorize_params`

    Array reference of parameter names.

    When constructing the authorization url,

    these parameters are copied from the current url query

    to the authorization url. This allows to add some

    dynamic configuration, but should be used with caution.

    Note that parameters from `authorize_params` always

    take precedence.

- `uid_key`

    Attribute from claims to be used as uid

    Note that all claims are also stored in `$session->get("auth_sso")->{info}`

# HOW IT WORKS

- the openid configuration is retrieved from `{openid_uri}`
    - key `authorization_endpoint` must be present in openid configuration
    - key `token_endpoint` must be present in openid configuration
    - key `jwks_uri` must be present in openid configuration
    - the user is redirected to the authorization endpoint with extra query parameters
- after authentication at the authorization endpoint, the user is redirected back to this url with query parameters `code` and `state`. When something happened at the authorization endpoint, query parameters `error` and `error_description` are returned, and no `code`.
- `code` is exchanged for a json string, using the token endpoint. This json string is a record that contains attributes like `id_token` and `access_token`. See [https://openid.net/specs/openid-connect-core-1\_0.html#TokenResponse](https://openid.net/specs/openid-connect-core-1_0.html#TokenResponse) for more information.
- key `id_token` in the token json string contains three parts:
    - jwt jose header. Can be decoded with base64 into a json string
    - jwt payload. Can be decoded with base64 into a json string
    - jwt signature
- the jwt payload from the `id_token` is decoded into a json string and then to a perl hash. All this data is stored `$session->{auth_sso}->{info}`. One of these attributes will be the uid that will be stored at `$session->{auth_sso}->{uid}`. This is determined by configuration key `uid_key` (see above). e.g. "email"

# NOTES

- Can I reauthenticate when I visit the application?

    When this Plack application is for example mounted at

    `/auth/oidc`, then you can reauthenticate by visiting

    it again, but it depends on your configuration what actually

    happens at the openid connect server. If `prompt` is not

    set anywhere (neither in `authorize_params` nor in the

    current url if that is allowed), then the external server

    will just sent you back with the same tokens.

    Note that `session("auth_sso")` is removed at the start

    of every (re)authentication.

# LOGGING

All subclasses of [Plack::Auth::SSO](https://metacpan.org/pod/Plack%3A%3AAuth%3A%3ASSO) use [Log::Any](https://metacpan.org/pod/Log%3A%3AAny)
to log messages to the category that equals the current
package name.

# AUTHOR

Nicolas Franck, `<nicolas.franck at ugent.be>`

# LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.

# SEE ALSO

[Plack::Auth::SSO](https://metacpan.org/pod/Plack%3A%3AAuth%3A%3ASSO)

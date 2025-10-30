# OIDC-Client

This distribution makes it easy to integrate the OpenID Connect protocol into different types of Perl applications.

You can use the [OIDC::Client](https://metacpan.org/pod/OIDC::Client) module directly for any batch or script. For use from within an application, you should instead use the framework plugin :

- [Mojolicious::Plugin::OIDC](https://metacpan.org/pod/Mojolicious::Plugin::OIDC)
- [Catalyst::Plugin::OIDC](https://metacpan.org/pod/Catalyst::Plugin::OIDC)
- [Dancer2::Plugin::OIDC](https://metacpan.org/pod/Dancer2::Plugin::OIDC)

## Features

- builds the authorization URL
- retrieves the provider metadata and JWK keys when the application is launched
- gets the token(s) from the provider
- includes a class for session management (token storage)
- refreshes the token(s)
- verifies a JWT token with support for automatic JWK key rotation
- introspects a token
- gets the user information from the *userinfo* endpoint
- exchanges the access token

## Documentation Index

- [Client module documentation](https://metacpan.org/pod/OIDC::Client)
- [Configuration](https://metacpan.org/pod/OIDC::Client::Config)

## Security Recommendation

When using OIDC-Client with an application, it is highly recommended to configure the framework to store session data, including sensitive tokens such as access and refresh tokens, on the backend rather than in client-side cookies. Although cookies can be signed and encrypted, storing tokens in the client exposes them to potential security threats.

## Limitations

- no support for *tls_client_auth* client authentication method
- no support for Implicit or Hybrid flows (applicable to front-end applications only and deprecated)

# Plack::Middleware::OIDC

OpenID Connect integration for PSGI/Plack applications.

This middleware lets a PSGI application act as an OpenID Connect Relying Party (user authentication) and as an OAuth 2.0 Resource Server (access token validation). It is built on the [OIDC-Client](https://metacpan.org/dist/OIDC-Client) distribution and is the PSGI/Plack counterpart of [Mojolicious::Plugin::OIDC](https://metacpan.org/pod/Mojolicious::Plugin::OIDC), [Catalyst::Plugin::OIDC](https://metacpan.org/pod/Catalyst::Plugin::OIDC) and [Dancer2::Plugin::OIDC](https://metacpan.org/pod/Dancer2::Plugin::OIDC).

It is meant for applications that do not use one of these frameworks (hand-written PSGI applications, etc...). If you use Mojolicious, Catalyst or Dancer2, prefer the dedicated plugin.

## Features

- automatically creates the endpoint used by the provider to redirect the user back to your application
- retrieves the provider metadata and JWK keys when the application is launched
- redirects the browser to the authorize URL to initiate an authorization code flow
- gets the token(s) from the provider
- the tokens are stored for later use or for future requests
- refreshes access token if needed
- verifies a JWT token with support for automatic JWK key rotation
- introspects the access token
- gets the user information from the *userinfo* endpoint
- exchanges the access token
- redirects the browser to the logout URL
- PKCE support

## Documentation

- [Plugin documentation](https://metacpan.org/pod/Plack::Middleware::OIDC)
- [Configuration](https://metacpan.org/pod/OIDC::Client::Config)

## Security Recommendation

When using Plack::Middleware::OIDC, it is highly recommended to configure the framework to store session data, including sensitive tokens such as access and refresh tokens, on the backend rather than in client-side cookies. Although cookies can be signed and encrypted, storing tokens in the client exposes them to potential security threats.

## Error handling and redirects

This middleware uses an explicit exception type to signal an OIDC redirect. Only this dedicated redirect exception is translated into an HTTP redirect response. Unexpected exceptions are not interpreted as authentication requests and are rethrown.

## Limitations

- no support for Implicit or Hybrid flows (applicable to front-end applications only and deprecated)

# OIDC-Client

This distribution makes it easy to integrate the OpenID Connect protocol into different types of Perl applications.  
It includes :

- specific plugins for applications using the Mojolicious or Catalyst frameworks. Other plugins could be added for other frameworks.
- a module for use with a batch or any script

## Features

- creates the endpoint used by the provider to redirect the user back to your application
- retrieves the provider metadata and JWK keys when the application is launched
- redirects the browser to the authorize URL to initiate an authorization code flow
- gets the token(s) from the provider
- manages the session : the tokens are stored to be used for next requests
- refreshes access token if needed
- verifies a JWT token with support for automatic JWK key rotation
- gets the user information from the *userinfo* endpoint
- exchanges the access token
- redirects the browser to the logout URL

## Security Recommendation

When using OIDC-Client with one of its framework plugins (e.g., for Mojolicious or Catalyst), it is highly recommended to configure the framework to store session data, including sensitive tokens such as access and refresh tokens, on the backend rather than in client-side cookies. Although cookies can be signed and encrypted, storing tokens in the client exposes them to potential security threats.

## Documentation Index

- Mojolicious Application

    [Plugin documentation](https://metacpan.org/pod/Mojolicious::Plugin::OIDC)

- Catalyst Application

    [Plugin documentation](https://metacpan.org/pod/Catalyst::Plugin::OIDC)

- Batch or script

    [Client module documentation](https://metacpan.org/pod/OIDC::Client)

## Limitations

- no multi-audience support
- no support for Implicit or Hybrid flows (applicable to front-end applications only and deprecated)

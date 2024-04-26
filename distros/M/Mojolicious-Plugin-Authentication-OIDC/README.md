# NAME

Mojolicious::Plugin::Authentication::OIDC - OpenID Connect implementation 
integrated into Mojolicious

# SYNOPSIS

    $self->plugin('Authentication::OIDC' => {
      client_secret  => '...',
      well_known_url => 'https://idp/realms/master/.well-known/openid-configuration',
      public_key     => "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----",
    });

    # in controller
    say "Hi " . $c->current_user->firstname;

    use Array::Utils qw(intersect);
    if(intersect($c->current_user_roles->@*, qw(admin))) { ... }

# DESCRIPTION

Mojolicious plugin for [OpenID Connect](https://openid.net/developers/how-connect-works/)
authentication. Designed to work with an OpenID Connect provider like Keycloak,
in confidential access mode. Its design goal is to be configured "all at once"
and then little-to-no effort should be needed to support it elsewhere -- this is 
largely achieved via hooks (["on\_success"](#on_success), ["on\_error"](#on_error), ["on\_login"](#on_login), 
["on\_activity"](#on_activity)) and handlers (["get\_token"](#get_token), ["get\_user"](#get_user), ["get\_roles"](#get_roles))

Controller actions `OpenIDConnect#redirect` and `OpenIDConnect#login` are
registered, and can be mapped to routes implicitly (see ["make\_routes"](#make_routes)) or 
manually routed to (e.g., via [Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AOpenAPI)).

For the auth workflow, clients should be sent to `OpenIDConnect#redirect` (via 
["redirect\_path"](#redirect_path) if ["make\_routes"](#make_routes) is enabled). Once the client authenticates
to the identity server, they'll be sent to `OpenIDConnect#login` (via 
["login\_path"](#login_path), again, if ["make\_routes"](#make_routes) is enabled). Upon successful login, the
["on\_login"](#on_login) hook will be called, followed by the ["on\_success"](#on_success) hook, which
should send the client to a post-login page. Then, on every server access 
on/after login, the ["on\_activity"](#on_activity) hook will be called.

Controllers may get information about the logged in user via the 
["current\_user"](#current_user) and ["current\_user\_roles"](#current_user_roles) helper methods.

# METHODS

[Mojolicious::Plugin::Authentication::OIDC](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAuthentication%3A%3AOIDC) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin) and imeplements the following new ones

## register( \\%params )

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application, including registering 
[Mojolicious::Plugin::Authentication::OIDC::Controller::OpenIDConnect](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAuthentication%3A%3AOIDC%3A%3AController%3A%3AOpenIDConnect) as a 
Mojolicious controller.

Configuration is done via the `\%params` HashRef, given the following keys

#### make\_routes

**Optional**

A flag to indicate whether routes should be registered for ["redirect\_path"](#redirect_path) and
["login\_path"](#login_path) pointing to 
["redirect" in Mojolicious::Plugin::Authentication::OIDC::Controller::OpenIDConnect](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAuthentication%3A%3AOIDC%3A%3AController%3A%3AOpenIDConnect#redirect)
and ["login" in Mojolicious::Plugin::Authentication::OIDC::Controller::OpenIDConnect](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAuthentication%3A%3AOIDC%3A%3AController%3A%3AOpenIDConnect#login),
respectively. Set to false if you are handling these routes some other way, for
instance in a [Mojolicious::PLugin::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APLugin%3A%3AOpenAPI) spec.  

Default: true

#### client\_id

**Optional**

The application's unique identifier, to the auhorization server

Default: the application moniker (lowercase)

#### client\_secret

**Required**

A secret value known to the authorization server, specific to this application

#### well\_known\_url 

**Required**

A discovery endpoint that informs the application of the authorization server's
specific configuration and capabilities

Example: `https://idp.domain.com/realms/master/.well-known/openid-configuration`

#### public\_key

**Required**

The RSA public key corresponding to the private key with which the authorization
tokens are signed by the authorization server. Format is a PEM/DER/JWT string
accepted by ["decode\_jwt" in Crypt::JWT](https://metacpan.org/pod/Crypt%3A%3AJWT#decode_jwt)'s `key` parameter.

#### redirect\_path

**Optional**

The path for the route which redirects users to the authorization server. Only
used when ["make\_routes"](#make_routes) is enabled, for configuring the path of that route.

Default: `/auth`

#### login\_path

**Optional**

The path section of the URL to be used as the OIDC `redirect_uri`. The full 
URL will be constructed based on the scheme/host/port of the request. This
path is also used for route registration if ["make\_routes"](#make_routes) is enabled.

Default: `/auth/login`

#### get\_user ( $token )

**Optional**

A callback that's given the auth token data as its only argument. It should
return the application's `user` instance corresponding to that data (e.g., a 
database record object), creating any references as necessary.

Default: Simply returns the auth token data as a HashRef

#### get\_token ( $controller )

**Optional**

A callback that's given a Mojolicious controller as its only argument. It should
return the encoded authorization token. This allows the application to choose
where and how the token is stored on the client side and sent to the server.

Default: returns the `token` value of the Mojo session

#### get\_roles ( $user, $token )

**Optional**

Given a `user` instance (produced by ["get\_user"](#get_user)) and a decoded authorization
token as arguments, returns an ArrayRef of roles pertaining to that user.

Default: returns an empty ArrayRef

#### on\_login ( $controller, $user )

**Optional**

A hook to allow the application to respond to a successful user login, such as
updating the user's `last_login` date. 

Default: `undef`

#### on\_activity ( $controller, $user )

**Optional**

A hook to allow the application to respond to any request by a logged-in user,
such as updating the user's `last_activity` date.

Default: `undef`

#### on\_success ( $controller, $token )

**Optional**

A hook invoked when the user's authorization request succeeds. This code should 
address storage of the authentication token on the frontend.

Default: Stores the (encrypted) token in the `token` key of the Mojo session
and redirects to `/login/success`

#### on\_error

**Optional**

A hook invoked when the user's authorization request fails.

Default: renders the Authorization Server's response (JSON)

## current\_user

Returns the user record (from ["get\_user"](#get_user)) for the currently logged in user.
If no user is logged in, or any failure occurs in reading their access token,
returns `undef`

## current\_user\_roles

If a user is logged in, returns their roles (as determined by ["get\_roles"](#get_roles)). 
Otherwise, returns `undef`

# AUTHOR

Mark Tyrrell `<mark@tyrrminal.dev>`

# LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

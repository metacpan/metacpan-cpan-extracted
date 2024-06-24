package Mojolicious::Plugin::Authentication::OIDC 0.06;
use v5.26;
use warnings;

# ABSTRACT: OpenID Connect implementation integrated into Mojolicious

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Authentication::OIDC - OpenID Connect implementation 
integrated into Mojolicious

=head1 SYNOPSIS

  $self->plugin('Authentication::OIDC' => {
    client_secret  => '...',
    well_known_url => 'https://idp/realms/master/.well-known/openid-configuration',
    public_key     => "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----",
  });

  # in controller
  say "Hi " . $c->authn->current_user->firstname;

  use Array::Utils qw(intersect);
  if(intersect($c->authn->current_user_roles->@*, qw(admin))) { ... }

=head1 DESCRIPTION

Mojolicious plugin for L<OpenID Connect|https://openid.net/developers/how-connect-works/>
authentication. Designed to work with an OpenID Connect provider like Keycloak,
in confidential access mode. Its design goal is to be configured "all at once"
and then little-to-no effort should be needed to support it elsewhere -- this is 
largely achieved via hooks (L</on_success>, L</on_error>, L</on_login>, 
L</on_activity>) and handlers (L</get_token>, L</get_user>, L</get_roles>)

Controller actions C<OpenIDConnect#redirect> and C<OpenIDConnect#login> are
registered, and can be mapped to routes implicitly (see L</make_routes>) or 
manually routed to (e.g., via L<Mojolicious::Plugin::OpenAPI>).

For the auth workflow, clients should be sent to C<OpenIDConnect#redirect> (via 
L</redirect_path> if L</make_routes> is enabled). Once the client authenticates
to the identity server, they'll be sent to C<OpenIDConnect#login> (via 
L</login_path>, again, if L</make_routes> is enabled). Upon successful login, the
L</on_login> hook will be called, followed by the L</on_success> hook, which
should send the client to a post-login page. Then, on every server access 
on/after login, the L</on_activity> hook will be called.

Controllers may get information about the logged in user via the 
L</current_user> and L</current_user_roles> helper methods.

=cut

use Mojo::Base 'Mojolicious::Plugin';

use Crypt::JWT qw(decode_jwt);
use Mojo::UserAgent;
use Readonly;
use Syntax::Keyword::Try;

use experimental qw(signatures);

Readonly::Array my @REQUIRED_PARAMS => qw(
  client_secret
  well_known_url
  public_key
);
Readonly::Array my @ALLOWED_PARAMS => qw(
  client_id on_login on_activity base_url
);
Readonly::Hash my %DEFAULT_PARAMS => (
  login_path    => '/auth/login',
  redirect_path => '/auth',
  make_routes   => 1,

  on_success => sub ($c, $token, $url) {$c->session(token => $token); $c->redirect_to($url)},
  on_error   => sub ($c, $error) {$c->render(json => $error)},

  get_token => sub ($c) {$c->session('token')},
  get_user  => sub ($token) {$token},
  get_roles => sub ($user, $token) {$user ? [] : undef},

  role_map => undef,
);
Readonly::Hash my %DEFAULT_CONSTANTS => (
  scope         => 'openid',
  response_type => 'code',
  grant_type    => 'authorization_code',
);
Readonly::Scalar my $DEFAULT_PREFIX => 'authn';

=head1 METHODS

L<Mojolicious::Plugin::Authentication::OIDC> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones

=head2 register( \%params )

Register plugin in L<Mojolicious> application, including registering 
L<Mojolicious::Plugin::Authentication::OIDC::Controller::OpenIDConnect> as a 
Mojolicious controller.

Configuration is done via the C<\%params> HashRef, given the following keys

=head4 make_routes

B<Optional>

A flag to indicate whether routes should be registered for L</redirect_path> and
L</login_path> pointing to 
L<Mojolicious::Plugin::Authentication::OIDC::Controller::OpenIDConnect/redirect>
and L<Mojolicious::Plugin::Authentication::OIDC::Controller::OpenIDConnect/login>,
respectively. Set to false if you are handling these routes some other way, for
instance in a L<Mojolicious::PLugin::OpenAPI> spec.  

Default: true

=head4 client_id

B<Optional>

The application's unique identifier, to the auhorization server

Default: the application moniker (lowercase)

=head4 client_secret

B<Required>

A secret value known to the authorization server, specific to this application

=head4 well_known_url 

B<Required>

A discovery endpoint that informs the application of the authorization server's
specific configuration and capabilities

Example: C<https://idp.domain.com/realms/master/.well-known/openid-configuration>

=head4 public_key

B<Required>

The RSA public key corresponding to the private key with which the authorization
tokens are signed by the authorization server. Format is a PEM/DER/JWT string
accepted by L<Crypt::JWT/decode_jwt>'s C<key> parameter.

=head4 redirect_path

B<Optional>

The path for the route which redirects users to the authorization server. Only
used when L</make_routes> is enabled, for configuring the path of that route.

Default: C</auth>

=head4 login_path

B<Optional>

The path section of the URL to be used as the OIDC C<redirect_uri>. The full 
URL will be constructed based on the scheme/host/port of the request. This
path is also used for route registration if L</make_routes> is enabled.

Default: C</auth/login>

=head4 get_user ( $token )

B<Optional>

A callback that's given the auth token data as its only argument. It should
return the application's C<user> instance corresponding to that data (e.g., a 
database record object), creating any references as necessary.

Default: Simply returns the auth token data as a HashRef


=head4 get_token ( $controller )

B<Optional>

A callback that's given a Mojolicious controller as its only argument. It should
return the encoded authorization token. This allows the application to choose
where and how the token is stored on the client side and sent to the server.

Default: returns the C<token> value of the Mojo session

=head4 get_roles ( $user, $token )

B<Optional>

Given a C<user> instance (produced by L</get_user>) and a decoded authorization
token as arguments, returns an ArrayRef of roles pertaining to that user.

Default: returns an empty ArrayRef

=head4 role_map (%map)

B<Optional>

A mapping of external roles (e.g., from Authorization Server) to internal roles
used by the application's authorization framework. If this option is specified,
roles not present in its keys are deleted, all others will be mapped.

=head4 on_login ( $controller, $user )

B<Optional>

A hook to allow the application to respond to a successful user login, such as
updating the user's C<last_login> date. 

Default: C<undef>

=head4 on_activity ( $controller, $user )

B<Optional>

A hook to allow the application to respond to any request by a logged-in user,
such as updating the user's C<last_activity> date.

Default: C<undef>

=head4 on_success ( $controller, $token )

B<Optional>

A hook invoked when the user's authorization request succeeds. This code should 
address storage of the authentication token on the frontend.

Default: Stores the (encrypted) token in the C<token> key of the Mojo session
and redirects to C</login/success>

=head4 on_error

B<Optional>

A hook invoked when the user's authorization request fails.

Default: renders the Authorization Server's response (JSON)

=head2 current_user

Returns the user record (from L</get_user>) for the currently logged in user.
If no user is logged in, or any failure occurs in reading their access token,
returns C<undef>

=head2 current_user_roles

If a user is logged in, returns their roles (as determined by L</get_roles>). 
Otherwise, returns C<undef>

=cut

sub register($self, $app, $params) {
  # Prefix handling
  my $prefix = $params->{prefix} // $DEFAULT_PREFIX;
  $prefix .= '.' if ($prefix);
  my $params_helper             = "__oidc_params";
  my $token_helper              = "__oidc_token";
  my $current_user_helper       = "${prefix}current_user";
  my $current_user_roles_helper = "${prefix}current_user_roles";
  # Parameter handling
  my %conf = (%DEFAULT_CONSTANTS, %DEFAULT_PARAMS, client_id => lc($app->moniker));
  $conf{$_} = $params->{$_} foreach (grep {exists($params->{$_})} (keys(%DEFAULT_PARAMS), @REQUIRED_PARAMS, @ALLOWED_PARAMS));
  # die if required/conditionally required params aren't found
  foreach (@REQUIRED_PARAMS) {die("Required param '$_' not found") unless (defined($conf{$_}))}
  die("Required param 'redirect_path' not found") if ($conf{make_routes} && !defined($conf{redirect_path}));

  # wrap success handler so that we can call login handler before finishing the req
  my $success_handler = $conf{on_success};
  $conf{on_success} = sub($c, $token, $url) {
    my $token_data = $c->app->renderer->get_helper($token_helper)->($c, $token);
    my $user       = $conf{get_user}->($token_data);
    $conf{on_login}->($c, $user) if ($conf{on_login});
    return $success_handler->($c, $token, $url);
  };

  # Add our controller to the namespace for calling via routes or, e.g., OpenAPI
  push($app->routes->namespaces->@*, 'Mojolicious::Plugin::Authentication::OIDC::Controller');

  # Fetch actual endpoints from well-known URL
  my $resp = Mojo::UserAgent->new()->get($conf{well_known_url});
  die("Unable to determine OIDC endpoints (" . $resp->res->error->{message} . ")\n") if ($resp->res->is_error);
  @conf{qw(auth_endpoint token_endpoint logout_endpoint)} =
    @{$resp->res->json}{qw(authorization_endpoint token_endpoint end_session_endpoint)};

  # internal helper for stored parameters (only to be used by OpenIDConnect controller)
  $app->helper(
    $params_helper => sub {
      return {map {$_ => $conf{$_}}
          qw(auth_endpoint scope response_type login_path token_endpoint client_id client_secret grant_type on_error on_success logout_endpoint base_url)
      };
    }
  );

  # internal helper for decoded auth token. Pass the token in, or it'll be retrieved
  # via `get_token` handler
  $app->helper(
    $token_helper => sub($c, $token = undef, $decode = 1) {
      my $t = $token // $conf{get_token}->($c);
      return $t unless ($decode);
      return undef if (!defined($t) || $t eq 'null');
      return decode_jwt(token => $t, key => \$conf{public_key});
    }
  );

  # public helper to access current user and OIDC roles
  $app->helper(
    $current_user_helper => sub($c) {
      my $t = $c->app->renderer->get_helper($token_helper)->($c);
      return undef if (!defined($t) || $t eq 'null');
      return $conf{get_user}->($t);
    }
  );
  $app->helper(
    $current_user_roles_helper => sub($c) {
      my ($user, $token);
      try {
        $token = $c->app->renderer->get_helper($token_helper)->($c);
        return [] unless ($token);
        $user = $c->app->renderer->get_helper($current_user_helper)->($c);
        my @roles = $conf{get_roles}->($user, $token)->@*;
        @roles = grep {defined} map {$conf{role_map}->{$_}} @roles if (defined($conf{role_map}));
        return [@roles];
      } catch ($e) {
        return undef
      }
      return undef;
    }
  );

  # if `on_activity` handler exists, call it from a before_dispatch hook
  $app->hook(
    before_dispatch => sub($c) {
      my $u;
      try {$u = $c->app->renderer->get_helper($current_user_helper)->($c);} catch ($e) {
      }
      $conf{on_activity}->($c, $u) if ($u);
    }
    )
    if ($conf{on_activity});
  # if `make_routes` is true, register our controller actions at the appropriate paths
  # otherwise, it's up to the downstream code to do this, e.g., via OpenAPI spec
  if ($conf{make_routes}) {
    $app->routes->get($conf{redirect_path})->to("OpenIDConnect#redirect");
    $app->routes->get($conf{login_path})->to('OpenIDConnect#login');
  }
}

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

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

=cut

1;

__END__

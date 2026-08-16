package Punk::Plugin::OAuth2;

use 5.024;
use strict;
use warnings;
use Carp ();
use Punk::OAuth2 ();            # XS core: the whole flow (_flow_begin,
use Punk::OAuth2::Provider ();  # _flow_complete, provider object, ...)

our $VERSION = '0.01';

my %STATE;

sub _state {
    my ($pkg) = @_;
    return $STATE{$pkg} //= {
        providers => {}, pending => {}, login => undef,
        registered => 0, keywords_used => 0,
    };
}

sub state_for { $STATE{ $_[1] // $_[0] } }   # test/introspection seam

# ---- import: the keywords ---------------------------------------------------

sub import {
    my ($class) = @_;
    my $caller = caller;
    return if $caller->can('oauth2');
    _install_keywords($caller);
    return;
}

sub _install_keywords {
    my ($pkg, $app) = @_;
    my $st = _state($pkg);

    $app ||= $pkg->can('punk_app') ? $pkg->punk_app
        : Carp::croak("Punk::Plugin::OAuth2: $pkg is not a Punk application "
                    . "- `use Punk` before `use Punk::Plugin::OAuth2`");

    if (!$st->{tripwire}) {
        $st->{tripwire} = 1;
        $app->middleware(sub {
            my ($inner) = @_;
            if ($st->{keywords_used} && !$st->{registered}) {
                Carp::croak("oauth2 used but plugin 'OAuth2' was never "
                          . "registered (add plugin 'OAuth2')");
            }
            if ($st->{registered} && !%{ $st->{providers} }
                && !%{ $st->{pending} } && !$st->{server}) {
                Carp::croak("plugin 'OAuth2' registered but no oauth2 "
                          . "providers or server were declared");
            }
            return $inner;
        });
    }

    return if $st->{keywords_installed};
    $st->{keywords_installed} = 1;

    # oauth2 NAME => \%cfg. Before registration the declaration only
    # records; after it, the provider builds at the declaration itself,
    # so either ordering works (the GraphQL plugin contract).
    $app->install_kw(oauth2 => sub {
        my ($name, $cfg) = @_;
        Carp::croak('oauth2: a provider name is required')
            unless defined $name && length $name;
        Carp::croak("oauth2 $name: a config hashref is required")
            unless ref $cfg eq 'HASH';
        $st->{keywords_used}++;
        $st->{pending}{$name} = $cfg;
        _build_pending($st) if $st->{registered};
        return;
    }, __PACKAGE__);

    # oauth2_login PATH => \%opts mounts the initiation and callback
    # routes at register (or at the declaration when already registered).
    $app->install_kw(oauth2_login => sub {
        my ($path, $opts) = @_;
        Carp::croak('oauth2_login: a path is required')
            unless defined $path && length $path;
        Carp::croak('oauth2_login: already declared')
            if $st->{login};
        $st->{keywords_used}++;
        $st->{login} = { path => $path, %{ $opts // {} } };
        _mount_login($st) if $st->{registered};
        return;
    }, __PACKAGE__);

    # oauth2_server PATH => \%opts mounts the authorization-server
    # endpoints. Its OAuth2 logic (grants, PKCE, client auth, token
    # minting) is all in XS; this records config, and register/here
    # builds the server object and wires the routes.
    $app->install_kw(oauth2_server => sub {
        my ($path, $opts) = @_;
        Carp::croak('oauth2_server: a path is required')
            unless defined $path && length $path;
        Carp::croak('oauth2_server: already declared')
            if $st->{server};
        $st->{keywords_used}++;
        $st->{server} = { path => $path, %{ $opts // {} } };
        _mount_server($st) if $st->{registered};
        return;
    }, __PACKAGE__);
    return;
}

# ---- register ---------------------------------------------------------------

sub new { bless {}, $_[0] }

sub register {
    my ($self, $app, $opts) = @_;
    $opts //= {};
    my $pkg = $app->caller_class
        or Carp::croak('Punk::Plugin::OAuth2: the app has no caller class');
    my $st = _state($pkg);

    _install_keywords($pkg, $app);
    $st->{app} = $app;

    # terse form: plugin 'OAuth2' => { providers => { name => {...} },
    # login => { path => ..., ... } }
    if (ref $opts->{providers} eq 'HASH') {
        $st->{pending}{$_} //= $opts->{providers}{$_}
            for keys %{ $opts->{providers} };
    }
    if (ref $opts->{login} eq 'HASH' && !$st->{login}) {
        my %l = %{ $opts->{login} };
        $l{path} //= '/auth';
        $st->{login} = \%l;
    }

    if (ref $opts->{server} eq 'HASH' && !$st->{server}) {
        my %s = %{ $opts->{server} };
        $s{path} //= '/oauth';
        $st->{server} = \%s;
    }

    $st->{registered} = 1;
    _build_pending($st);
    _install_helpers($st);
    _mount_login($st)  if $st->{login};
    _mount_server($st) if $st->{server};
    return;
}

# Mount the authorization-server endpoints. The Server object holds all
# protocol logic (XS); the routes are thin dispatchers to its methods.
# The token/revoke/introspect POSTs are client-authenticated APIs with no
# cookies, so they are mounted csrf-exempt.
sub _mount_server {
    my ($st) = @_;
    return if $st->{server_mounted}++;
    require Punk::OAuth2::Server;
    require Punk::OAuth2::Server::Store;
    my $app = $st->{app};
    my $cfg = $st->{server};
    (my $path = $cfg->{path}) =~ s{/\z}{};

    # resolve authenticate/consent targets
    for my $hook (qw(authenticate consent)) {
        next unless defined $cfg->{$hook} && ref $cfg->{$hook} ne 'CODE';
        $cfg->{$hook} = $app->_resolve_target($cfg->{$hook},
                                              "oauth2_server $hook");
    }

    # build the store from a dsn/hashref, or accept a ready store object
    my $store = $cfg->{store};
    $store = Punk::OAuth2::Server::Store->new(%$store)
        if ref $store eq 'HASH';
    Carp::croak('oauth2_server: a store is required (store => { dsn => ... })')
        unless $store;
    $st->{server_store} = $store;   # introspection seam for tests/admin

    my $server = Punk::OAuth2::Server->new(
        issuer => $cfg->{issuer},
        store  => $store,
        prefix => $path,
        (map { defined $cfg->{$_} ? ($_ => $cfg->{$_}) : () }
             qw(alg at_ttl rt_ttl oidc authenticate consent key)),
    );
    $st->{server_obj} = $server;

    $app->route('GET',  "$path/authorize" => sub { $server->authorize($_[0]) });
    $app->route('POST', "$path/authorize" => sub { $server->authorize($_[0]) });
    $app->route('POST', "$path/token"     => sub { $server->token($_[0]) });
    $app->route('POST', "$path/revoke"    => sub { $server->revoke($_[0]) });
    $app->route('POST', "$path/introspect"=> sub { $server->introspect($_[0]) });
    $app->route('GET',  "$path/jwks.json" => sub { $server->jwks($_[0]) });
    $app->route('GET', '/.well-known/oauth-authorization-server'
        => sub { $server->metadata($_[0]) });
    $app->route('GET', '/.well-known/openid-configuration'
        => sub { $server->metadata($_[0]) });

    # client-authenticated token endpoints carry no cookies -> csrf exempt
    if ($app->can('csrf') && $app->{csrf}) {
        eval { $app->csrf(exempt => ["$path/token", "$path/revoke",
                                     "$path/introspect"]) };
    }
    return;
}

sub _build_pending {
    my ($st) = @_;
    for my $name (sort keys %{ $st->{pending} }) {
        my $cfg = delete $st->{pending}{$name};
        Carp::croak("oauth2: duplicate provider '$name'")
            if $st->{providers}{$name};
        $st->{providers}{$name} =
            Punk::OAuth2::Provider->new($name, %$cfg);
    }
    return;
}

sub _provider {
    my ($st, $name) = @_;
    return defined $name ? $st->{providers}{$name} : undef;
}

sub _install_helpers {
    my ($st) = @_;
    return if $st->{helpers_installed}++;
    my $app = $st->{app};

    $app->helper(oauth2_provider => sub {
        my ($c, $name) = @_;
        return _provider($st, $name)
            // Carp::croak("oauth2: unknown provider '"
                         . ($name // '') . "'");
    }, __PACKAGE__);

    # Build an authorization URL by hand (custom buttons): this ALSO
    # records the flow in the session - a URL without a flow record
    # could never complete its callback.
    $app->helper(oauth2_authurl => sub {
        my ($c, $name, %ov) = @_;
        my $provider = _provider($st, $name)
            // Carp::croak("oauth2: unknown provider '"
                         . ($name // '') . "'");
        my $login = $st->{login}
            or Carp::croak('oauth2: oauth2_login is not mounted');
        return Punk::OAuth2::_flow_begin($c, $provider, $login,
                                         $ov{return_to});
    }, __PACKAGE__);

    $app->helper(oauth2_refresh => sub {
        my ($c, $name, $refresh) = @_;
        my $provider = _provider($st, $name)
            // Carp::croak("oauth2: unknown provider '"
                         . ($name // '') . "'");
        $provider->ensure_endpoints($c);
        return $provider->refresh($c, $refresh);
    }, __PACKAGE__);
    return;
}

# ---- the flows --------------------------------------------------------------
#
# The flow logic lives in XS (Punk::OAuth2::_flow_begin / _flow_complete):
# state/nonce/PKCE minting, session flow records with TTL and a
# concurrency cap, the callback's state/iss/code validation, the token
# exchange, and identity normalization all run in C. What remains here is
# Punk registration wiring - route/helper installation - and mapping the
# XS result onto a response.

sub _mount_login {
    my ($st) = @_;
    return if $st->{login_mounted}++;
    my $app   = $st->{app};
    my $login = $st->{login};
    Carp::croak('oauth2_login: the login flow stores state in the '
              . 'session - add a `session` keyword first')
        unless $app->{session};
    (my $path = $login->{path}) =~ s{/\z}{};

    my $on_login = $login->{on_login}
        or Carp::croak('oauth2_login: an on_login handler is required');
    $on_login = $app->_resolve_target($on_login, 'oauth2_login on_login')
        if ref $on_login ne 'CODE';
    $login->{on_login} = $on_login;

    $app->route('GET', "$path/:provider" => sub {
        my ($c) = @_;
        my $provider = _provider($st, $c->param('provider'))
            or return $c->not_found;
        my $return_to = Punk::OAuth2::same_origin_path(
            $c->req->query->{return});
        my $url = eval {
            Punk::OAuth2::_flow_begin($c, $provider, $login, $return_to);
        };
        return _flow_error($c, $login, "oauth2: $@") unless defined $url;
        return $c->redirect($url);
    });

    $app->route('GET', "$path/:provider/callback" => sub {
        my ($c) = @_;
        my $provider = _provider($st, $c->param('provider'))
            or return $c->not_found;
        my ($identity, $tokens) = eval {
            Punk::OAuth2::_flow_complete($c, $provider, $login);
        };
        return _flow_error($c, $login, $@) unless $identity;

        my $return_to = delete $identity->{_return_to};
        my $ret = $login->{on_login}->($c, $identity, $tokens);
        return $ret if ref $ret;
        return $c->redirect($return_to // $login->{redirect_ok} // '/');
    });
    return;
}

# Login failures render a minimal page (or the app's own handler); the
# detail goes to the log, not the browser.
sub _flow_error {
    my ($c, $login, $detail) = @_;
    warn "Punk::Plugin::OAuth2: $detail\n";
    if (my $h = $login->{on_error}) {
        my $ret = $h->($c);
        return $ret if ref $ret;
    }
    my $body = 'Login failed. Please try again.';
    return [400,
            ['Content-Type'   => 'text/plain; charset=utf-8',
             'Content-Length' => length $body],
            [$body]];
}

1;

=head1 NAME

Punk::Plugin::OAuth2 - social login for Punk applications

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	package MyApp;
	use Punk;
	use Punk::Plugin::OAuth2;

	plugin 'OAuth2';

	session secret => secret('session_key'), expires => '7d';

	oauth2 google => {
		preset        => 'google',
		client_id     => secret('oauth.google_id'),
		client_secret => secret('oauth.google_secret'),
	};
	oauth2 github => {
		preset        => 'github',
		client_id     => secret('oauth.github_id'),
		client_secret => secret('oauth.github_secret'),
	};
	oauth2 corp => {
		issuer        => 'https://idp.corp.example',
		discovery     => 1,
		client_id     => '...',
		client_secret => '...',
	};

	oauth2_login '/auth' => {
		on_login => 'Auth#on_login',
		base_url => 'https://app.example.com',
	};

	package MyApp::Controller::Auth;

	sub on_login {
		my ($c, $identity, $tokens) = @_;
		$c->session->{user} = { id => find_user($identity)->id };
		return;   # falls through to the post-login redirect
	}

=head1 DESCRIPTION

OAuth2 and OpenID Connect for L<Punk>. The plugin installs three
keywords covering both sides of the protocol:

=over 4

=item *

C<oauth2> + C<oauth2_login> - the B<client> (social login):
authorization-code flow with PKCE (S256 only), single-use signed state,
OIDC nonce, id_token verification through L<Crypt::JWS> and a cached
JWKS, and normalized identities across providers.

=item *

C<oauth2_server> - a full B<authorization server> (see
L<Punk::OAuth2::Server>).

=back

For the B<resource-server> side (validating incoming Bearer tokens as
route guards or in an OpenAPI security map) see L<Punk::OAuth2::Checker>.

Declaring a provider records configuration; C<plugin 'OAuth2'> builds
providers and mounts routes - either ordering of keyword and plugin
works, and mismatches croak at C<to_app>.

C<oauth2_login '/auth'> mounts C<GET /auth/:provider> (starts a login)
and C<GET /auth/:provider/callback> (completes it). Flow state lives in
the signed session - at most three concurrent login attempts, each
valid for ten minutes, deleted on use. Tokens are handed to C<on_login>
and then discarded: nothing token-shaped is ever stored in the session.

=head1 KEYWORDS

=head2 oauth2 NAME => \%config

Declares a provider. C<preset> is C<google>, C<github>, or C<oidc>;
every preset field can be overridden. Without a preset, set C<issuer>
plus C<< discovery => 1 >> (endpoints from the OIDC discovery document,
issuer-checked and SSRF-guarded) or explicit
C<authorization_endpoint>/C<token_endpoint>. Other options:

=over 4

=item client_id / client_secret

The registration with the provider. C<client_secret> may be omitted for
a public client (C<< public => 1 >>) - PKCE still applies.

=item scope

Space-separated scope string; presets carry sensible defaults.

=item auth_method

C<basic> (default) or C<body> - how client credentials reach the token
endpoint.

=item algs

id_token signature allowlist, default C<['RS256', 'ES256']>.

=item allow_local

Relax the SSRF guard for loopback IdPs (development and tests).

=item ua

A Fetch-compatible agent or a coderef returning one - the test seam;
defaults to C<< $c->ua >>.

=back

=head2 oauth2_login PATH => \%options

Mounts the login routes. Options:

=over 4

=item on_login (required)

Coderef or C<'Controller#method'>, called as
C<< ($c, $identity, $tokens) >> after a verified login. C<$identity> is
C<{ provider, sub, email, email_verified, name, picture, raw }>;
C<$tokens> is a L<Punk::OAuth2::Tokens>. A returned reference becomes
the response; otherwise the user is redirected to the flow's C<return>
destination or C<redirect_ok>.

=item base_url

The application's external origin, used to build exact redirect URIs.
Required in production; C<< trust_proxy => 1 >> derives it from
X-Forwarded-Proto/Host instead when running behind a trusted proxy.

=item redirect_ok

Default post-login destination (C</>). A C<?return=> parameter on the
initiation URL overrides it when it is a same-origin relative path -
absolute and protocol-relative destinations are ignored.

=item on_error

Optional handler for failed logins; the default is a plain 400 page.
Details go to the log, never the browser.

=back

=head2 oauth2_server PATH => \%options

Mounts an OAuth2 / OpenID Connect authorization server at C<PATH>: the
C<authorize>, C<token>, C<revoke>, C<introspect>, and C<jwks.json>
endpoints, plus the RFC 8414 metadata at
C<< /.well-known/oauth-authorization-server >> and
C<< /.well-known/openid-configuration >> (registered at the app root).
The C<token>, C<revoke>, and C<introspect> POSTs are client-authenticated
and are mounted CSRF-exempt.

	oauth2_server '/oauth' => {
		issuer       => 'https://idp.example.com',
		store        => { dsn => 'dbi:SQLite:idp.db' },
		authenticate => 'Auth#require_user',
		consent      => 'Auth#consent',
	};

Grants: authorization code with PKCE (S256 only), C<refresh_token> (with
rotation and family revocation on reuse), and C<client_credentials>.
Access tokens are ES256 JWTs. See L<Punk::OAuth2::Server> for the full
behaviour. Options:

=over 4

=item issuer (required)

The issuer URL; it appears in tokens and metadata and must match what
resource servers expect.

=item store (required)

A L<Punk::OAuth2::Server::Store>, a C<{ dsn => ... }> hashref (built into
one for you), or any object satisfying the store contract - see
L<Punk::OAuth2::Server::Store/"CREATING YOUR OWN STORE">.

=item authenticate (required)

Coderef or C<'Controller#method'>, called with the context; returns the
authenticated user id, or a reference (a login redirect) that
short-circuits the authorization request.

	sub require_user {
		my ($c) = @_;
		return $c->session->{user_id} if $c->session->{user_id};
		return $c->redirect('/login?to=' . ...);   # a reference wins
	}

=item consent

Optional. Called as C<< ($c, $client, \@scopes) >>; returns 1 (approve),
0 (deny), or a reference (render a consent page). Approvals are
persisted so returning users skip consent.

=item alg, at_ttl, rt_ttl, key

Signing algorithm (default C<ES256>), access- and refresh-token
lifetimes (seconds), and an explicit signing key (a L<Crypt::JWS::Key>;
one is generated otherwise).

	oauth2_server '/oauth' => {
		issuer => ..., store => ...,
		authenticate => ...,
		alg => 'ES256', at_ttl => 600, rt_ttl => 30 * 86400,
	};

=back

Both keyword and plugin orderings work, and inline declaration via
C<< plugin 'OAuth2' => { server => {...} } >> is equivalent to the
keyword.

=head1 CONTEXT HELPERS

The plugin installs these on the context for use inside handlers.

=head2 oauth2_authurl

	get '/signin' => sub {
		my ($c) = @_;
		my $url = $c->oauth2_authurl('google', return_to => '/dashboard');
		return $c->render(template => 'signin', google_url => $url);
	};

Builds the authorization URL for a provider (for hand-rolled sign-in
buttons) and records the login flow in the session, so its callback can
complete just like C<oauth2_login>'s own route. C<return_to> is an
optional post-login destination.

=head2 oauth2_refresh

	my $fresh = $c->oauth2_refresh('google', $tokens);
	# or with a raw refresh-token string:
	my $fresh = $c->oauth2_refresh('google', $refresh_token);

Performs a refresh-token grant against the provider and returns a fresh
L<Punk::OAuth2::Tokens>.

=head2 oauth2_provider

	my $provider = $c->oauth2_provider('google');
	my $url      = $provider->authorize_url(...);

Returns the configured L<Punk::OAuth2::Provider> object for advanced use.

=head1 SECURITY NOTES

PKCE is always on and S256 only. State is 256 random bits, single-use,
ten-minute lifetime. The OIDC nonce is checked against the id_token in
constant time. id_token verification enforces the algorithm allowlist,
issuer equality, audience (and azp with multiple audiences), and
expiry with 60 seconds of leeway. Discovery and JWKS URLs must be https
and resolve to public addresses unless C<allow_local> is set. The
C<?return=> destination is constrained to same-origin relative paths.
Provider tokens are never written to the session.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut

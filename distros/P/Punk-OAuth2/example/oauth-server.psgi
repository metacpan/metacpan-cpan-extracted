#!/usr/bin/env perl
use strict;
use warnings;

# A complete, runnable OAuth2 / OIDC authorization server on Punk.
#
#   hyperman example/oauth-server.psgi        # http://localhost:5000
#
# It mounts the authorization server at /oauth, a tiny cookie-session
# login + consent flow, and a resource server at /api protected by a
# checker that validates the server's own tokens. A demo client is
# registered on boot. See example/README.md for a curl walkthrough.
#
# This is a demo: the login accepts any username and consent is
# auto-approved. Do not deploy it as-is.

package OAuthDemo;
use Punk;
use Punk::Plugin::OAuth2;
use Punk::OAuth2::Server::Store;
use Punk::OAuth2::Checker;
use Crypt::JWS ();
use Crypt::JWS::Key ();

our $ISSUER = $ENV{OAUTH_DEMO_ISSUER} || 'http://localhost:5000';

# One ES256 signing key, shared by the server (to sign) and the resource
# server's checker (to verify) - so the demo needs no JWKS self-fetch and
# runs with a single worker.
our $KEY = Crypt::JWS::Key->generate('ES256');

# A file-backed store with one demo client registered at boot.
our $STORE = Punk::OAuth2::Server::Store->new(
    dsn => 'dbi:SQLite:dbname=' . ($ENV{OAUTH_DEMO_DB} || '/tmp/oauth-demo.db'),
);
$STORE->client_put({
    client_id     => 'demo-client',
    secret        => 'demo-secret',
    name          => 'Demo Client',
    redirect_uris => [ "$ISSUER/callback",
                       'urn:ietf:wg:oauth:2.0:oob' ],
    scopes        => 'read write',
});

session secret => ($ENV{OAUTH_DEMO_SESSION_KEY} || 'demo-session-key'),
        expires => '1d';

plugin 'OAuth2';

# The authorization server.
oauth2_server '/oauth' => {
    issuer       => $ISSUER,
    store        => $STORE,
    key          => $KEY,
    authenticate => 'Auth#require_user',
    consent      => 'Auth#consent',
};

# A resource server: /api/me returns the caller's identity, validated
# statelessly from the same signing key.
my $checker = Punk::OAuth2::Checker->jwt(
    issuer   => $ISSUER,
    audience => $ISSUER,
    key      => $KEY,
    algs     => ['ES256'],
);
my $api = under '/api' => Punk::OAuth2::Checker->guard($checker,
                                                       scopes => ['read']);
$api->get('/me' => sub {
    my ($c) = @_;
    my $claims = $c->stash->{auth}{oauth};
    return $c->json({
        subject   => $claims->{sub},
        client_id => $claims->{client_id},
        scope     => $claims->{scope},
        expires   => $claims->{exp},
    });
});

# A home page with the demo details.
get '/' => sub {
    my ($c) = @_;
    my $html = <<"HTML";
<!doctype html><meta charset=utf-8>
<title>Punk OAuth2 demo</title>
<style>body{font:15px/1.5 system-ui;margin:3rem auto;max-width:44rem}
code,pre{background:#f4f4f5;padding:.1em .3em;border-radius:4px}
pre{padding:1rem;overflow:auto}</style>
<h1>Punk OAuth2 authorization server</h1>
<p>Issuer: <code>$OAuthDemo::ISSUER</code></p>
<p>Registered client: <code>demo-client</code> /
   <code>demo-secret</code>, redirect
   <code>$OAuthDemo::ISSUER/callback</code>, scopes <code>read write</code>.</p>
<h2>Endpoints</h2>
<ul>
<li><a href="/.well-known/oauth-authorization-server">/.well-known/oauth-authorization-server</a></li>
<li><a href="/oauth/jwks.json">/oauth/jwks.json</a></li>
<li><code>/oauth/authorize</code>, <code>/oauth/token</code>,
    <code>/oauth/revoke</code>, <code>/oauth/introspect</code></li>
<li><code>/api/me</code> (Bearer-protected, scope <code>read</code>)</li>
</ul>
<h2>Quick client-credentials demo</h2>
<pre>curl -s -u demo-client:demo-secret \\
  -d grant_type=client_credentials -d scope=read \\
  $OAuthDemo::ISSUER/oauth/token

curl -s -H "Authorization: Bearer \$TOKEN" $OAuthDemo::ISSUER/api/me</pre>
<p>See <code>example/README.md</code> for the full authorization-code +
PKCE walkthrough (browser login below).</p>
HTML
    return [200, ['Content-Type' => 'text/html; charset=utf-8',
                  'Content-Length' => length $html], [$html]];
};

# A trivial login page + handler for the browser authorization-code flow.
get '/login' => sub {
    my ($c) = @_;
    my $to = $c->req->query->{to} // '/';
    $to =~ s/"/&quot;/g;
    my $html = <<"HTML";
<!doctype html><meta charset=utf-8><title>Log in</title>
<style>body{font:15px/1.5 system-ui;margin:4rem auto;max-width:22rem}
input,button{font:inherit;padding:.4rem;width:100%;margin:.3rem 0}</style>
<h1>Demo login</h1>
<p>Any username works in this demo.</p>
<form method=post action=/login>
  <input name=username placeholder=username autofocus required>
  <input type=hidden name=to value="$to">
  <button>Log in</button>
</form>
HTML
    return [200, ['Content-Type' => 'text/html; charset=utf-8',
                  'Content-Length' => length $html], [$html]];
};

post '/login' => sub {
    my ($c) = @_;
    my $form = $c->req->form;
    my $user = $form->{username};
    return $c->redirect('/login') unless defined $user && length $user;
    $c->session->{user_id} = $user;
    my $to = $form->{to};
    # only same-origin relative destinations
    $to = '/' unless defined $to && $to =~ m{\A/} && $to !~ m{\A//};
    return $c->redirect($to);
};

get '/logout' => sub {
    my ($c) = @_;
    $c->session_expire;
    return $c->redirect('/');
};

package OAuthDemo::Controller::Auth;

# The authorize hook: return the logged-in user, or bounce to /login
# preserving the original authorize request (a returned reference
# short-circuits the authorization-server flow).
sub require_user {
    my ($c) = @_;
    return $c->session->{user_id} if $c->session->{user_id};
    my $env = $c->req->env;
    my $here = $env->{PATH_INFO}
             . (length($env->{QUERY_STRING} // '')
                ? "?$env->{QUERY_STRING}" : '');
    $here =~ s/([^A-Za-z0-9\-._~\/?&=])/sprintf '%%%02X', ord $1/ge;
    return $c->redirect("/login?to=$here");
}

# Consent: auto-approve for the demo. A real app renders a page and
# returns a reference, or returns 0 to deny.
sub consent {
    my ($c, $client, $scopes) = @_;
    return 1;
}

package main;
OAuthDemo->to_app;

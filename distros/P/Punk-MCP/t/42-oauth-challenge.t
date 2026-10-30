#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
    plan skip_all => 'Punk-OAuth2 0.08 and Crypt::JWS required'
        unless eval { require Punk::OAuth2::Checker; Punk::OAuth2->VERSION('0.08');
                      require Crypt::JWS; 1 };
}
use PMCPAuth;

my $OAUTH = q{oauth => { issuer => 'https://id.test', key => $PMCPAuth::SECRET,
                         algs => ['HS256'], scopes => ['mcp'] }};
my $t = auth_app($OAUTH);
my $PRM = 'http://localhost/.well-known/oauth-protected-resource/mcp';

mcp_call($t);
is($t->status, 401, 'no token: 401');
my $www = $t->header('WWW-Authenticate') // '';
like($www, qr/^Bearer /, 'a Bearer challenge');
like($www, qr/resource_metadata="\Q$PRM\E"/, 'naming the RFC 9728 document');
like($www, qr/scope="mcp"/, 'and, on a 401, the scope to ask for');

mcp_call($t, Authorization => 'Bearer ' . token(aud => 'https://elsewhere.test/mcp'));
is($t->status, 401, 'a token for another resource: 401');
like($t->header('WWW-Authenticate'), qr/error="invalid_token"/, 'invalid_token');
like($t->header('WWW-Authenticate'), qr/scope="mcp"/, 'still naming the scope');

mcp_call($t, Authorization => 'Bearer ' . token(iss => 'https://other-idp.test'));
is($t->status, 401, 'a token from another issuer: 401');

mcp_call($t, Authorization => 'Bearer ' . token(exp => time - 3600));
is($t->status, 401, 'an expired token: 401');

mcp_call($t, Authorization => 'Bearer ' . token(scope => 'read'));
is($t->status, 403, 'a token without the scope: 403');
like($t->header('WWW-Authenticate'), qr/error="insufficient_scope", scope="mcp"/,
    'insufficient_scope, naming the scope missing');

mcp_call($t, Authorization => 'Bearer ' . token(sub => 'ada'));
is($t->status, 200, 'a good token: let in');
is(JSON::PP->new->decode($t->body)->{result}{structuredContent}{sub}, 'ada',
    'and the claims are in stash->{auth}{oauth}, in the tool');

# ---- what boot refuses -------------------------------------------------------------

my $err;
eval { auth_app($OAUTH, host => '') }; $err = $@;
like($err, qr/oauth needs the application's `host`/, 'oauth with no host croaks');
eval { auth_app(q{oauth => { key => 'x' }}) }; $err = $@;
like($err, qr/oauth needs `issuer`/, 'no issuer croaks');
eval { auth_app(q{oauth => { issuer => 'https://id.test' }}) }; $err = $@;
like($err, qr/exactly one of `jwks_url`, `key` or `introspect`/, 'no way to check croaks');
eval { auth_app(q{oauth => { issuer => 'https://id.test', key => 'x', jwks_url => 'https://id.test/j' }}) };
like($@, qr/exactly one of/, 'two ways croak');
eval { auth_app(q{oauth => { issuer => 'https://id.test', key => 'x', scope => 'mcp' }}) };
like($@, qr/unknown oauth option 'scope'/, 'an unknown oauth option croaks');

done_testing;

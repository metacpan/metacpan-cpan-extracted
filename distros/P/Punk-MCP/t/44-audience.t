#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
    plan skip_all => 'Punk-OAuth2 0.08 and Crypt::JWS required'
        unless eval { require Punk::OAuth2::Checker; Punk::OAuth2->VERSION('0.08');
                      require Crypt::JWS; 1 };
}
use PMCPAuth;

# RFC 8707: a token is bound to the resource it was asked for, and refused by
# every other. The default audience is this endpoint's URL.

my $t = auth_app(q{oauth => { issuer => 'https://id.test', key => $PMCPAuth::SECRET,
                              algs => ['HS256'], scopes => ['mcp'] }});
is(mcp_call($t, Authorization => 'Bearer ' . token())->status, 200,
    'a token for http://localhost/mcp, the host and path, is accepted');
is(mcp_call($t, Authorization => 'Bearer ' . token(aud => 'http://localhost/api'))->status, 401,
    'one for another path on the same host is not');
is(mcp_call($t, Authorization => 'Bearer ' . token(aud => ['http://localhost/mcp', 'x']))->status,
    200, 'an aud list that includes this resource is');

$t = auth_app(q{oauth => { issuer => 'https://id.test', key => $PMCPAuth::SECRET,
                           algs => ['HS256'], scopes => ['mcp'],
                           audience => ['http://localhost/mcp', 'https://api.acme.test'] }});
is(mcp_call($t, Authorization => 'Bearer ' . token())->status, 200,
    'an audience list: the first');
is(mcp_call($t, Authorization => 'Bearer ' . token(aud => 'https://api.acme.test'))->status, 200,
    'the second');
is(mcp_call($t, Authorization => 'Bearer ' . token(aud => 'https://evil.test'))->status, 401,
    'and nothing else');

# ---- introspection: the audience is checked here, as the server may not -------------

my $claims;
my $fake = sub { $claims };
my $chk = Punk::Plugin::MCP::_aud_checker($fake, ['http://localhost/mcp']);
$claims = { active => 1, aud => 'http://localhost/mcp', sub => 'a' };
is(ref $chk->('tok'), 'HASH', 'introspected claims naming this resource pass');
$claims = { active => 1, aud => ['x', 'http://localhost/mcp'] };
is(ref $chk->('tok'), 'HASH', 'as a list too');
$claims = { active => 1, aud => 'https://evil.test' };
ok(!$chk->('tok'), 'claims for another resource do not');
$claims = { active => 1, sub => 'a' };
ok(!$chk->('tok'), 'nor do claims that name no audience at all');
$claims = undef;
ok(!$chk->('tok'), 'nor does an inactive token');

done_testing;

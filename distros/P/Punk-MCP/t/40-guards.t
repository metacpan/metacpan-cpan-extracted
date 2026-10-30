#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPAuth;
use PMCPSess;

sub who { JSON::PP->new->decode($_[0]->body)->{result}{structuredContent} }

# ---- one guard, a string guard, a list --------------------------------------------

my $t = auth_app(q{auth => sub { ($_[0]->req->header('X-Pass') // '') eq 'yes' ? undef : [401, ['Content-Type' => 'text/plain'], ['say the word']] }});
mcp_call($t);
is($t->status, 401, 'a code ref guard refuses');
is($t->body, 'say the word', 'with the response it made, as it made it');
mcp_call($t, 'X-Pass' => 'yes');
is($t->status, 200, 'and lets the right request in');

$t = auth_app(q{auth => 'T#deny'});
is(mcp_call($t)->status, 401, "a 'Controller#method' guard is resolved and run");
is(mcp_call($t, 'X-Pass' => 'yes')->status, 200, 'and passes');

$t = auth_app(q{auth => [sub { return }, 'T#deny']});
is(mcp_call($t)->status, 401, 'a list: every guard must pass');
is(mcp_call($t, 'X-Pass' => 'yes')->status, 200, 'all passing lets it in');

# Guards run before the body is read: a body that is not JSON still gets the 401.
$t = auth_app(q{auth => 'T#deny'});
$t->post_ok('/mcp', body => '{not json', type => 'application/json');
is($t->status, 401, 'the guard runs before the body is parsed');

$t->post_ok('/mcp', body => '{}', type => 'application/json',
            headers => { Origin => 'http://localhost' }, env => { HTTP_HOST => 'localhost' });
is($t->header('Access-Control-Expose-Headers'),
    'Mcp-Session-Id, MCP-Protocol-Version, WWW-Authenticate',
    'a refusal to a browser exposes its challenge');

# ---- principal ------------------------------------------------------------------------------

$t = auth_app(q{principal => 'T#me'});
is(who(mcp_call($t, 'X-User' => 'ada'))->{user}, 'principal-from-ada',
    'principal gives $c->mcp_user, inside the tool call');
$t = auth_app(q{principal => sub { 'from-code' }});
is(who(mcp_call($t))->{user}, 'from-code', 'a code ref principal too');
$t = auth_app('');
ok(!defined who(mcp_call($t))->{user}, 'without one, current_user, here nobody');

# ---- the same guards on GET and DELETE ---------------------------------------------------

my $s = sess_app(q{auth => sub { ($_[0]->req->header('Authorization') // '') =~ /^Bearer ok/ ? undef : [401, [], ['no']] }});
my ($sid, $code) = init_session($s);
is($code, 401, 'with sessions, initialize is guarded');
($sid, $code) = init_session($s, auth => 'Bearer ok-1');
is($code, 200, 'and made with the credential');
$s->get_ok('/mcp', headers => { Accept => 'text/event-stream', 'Mcp-Session-Id' => $sid });
is($s->status, 401, 'GET runs the guards');
is((send_msg($s, undef, sid => $sid, http => 'DELETE'))[0], 401, 'and so does DELETE');
is((send_msg($s, undef, sid => $sid, auth => 'Bearer ok-1', http => 'DELETE'))[0], 204,
    'which passes with the credential');

done_testing;

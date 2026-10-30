#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPOA;

# The mount's security runs on the inner request: an OpenAPI tool is never a
# way round it.

my $t = oa_app(q{openapi => '*'});

my $r = oa_call($t, 'adminop', {})->{result};
ok($r->{isError}, 'no credential: the mount\'s checker refuses, and it is a tool error');
is($r->{_meta}{status}, 401, 'with the mount\'s 401, not a bypass');

$r = oa_call($t, 'adminop', {}, Authorization => 'Bearer wrong')->{result};
is($r->{_meta}{status}, 401, 'a credential the checker refuses: 401');

$r = oa_call($t, 'adminop', {}, Authorization => 'Bearer ok')->{result};
ok(!$r->{isError}, 'the caller\'s own credential, carried to the mount, is let in');
is_deeply($r->{structuredContent}, { admin => 1, who => { who => 'ok' } },
    'and the checker\'s claims reach the operation');

$r = oa_call($t, 'listbooks', {})->{result};
ok(!$r->{isError}, 'an operation without security needs none');

# The endpoint's own auth and the mount's both apply: auth first, at the door.
$t = oa_app(q{openapi => '*', auth => sub { ($_[0]->req->header('X-Door') // '') eq 'open' ? undef : [403, [], ['shut']] }});
$t->post_ok('/mcp', body => '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"adminop","arguments":{}}}',
            type => 'application/json', headers => { Authorization => 'Bearer ok' });
is($t->status, 403, 'the endpoint guard refuses before the mount is reached');
$r = oa_call($t, 'adminop', {}, Authorization => 'Bearer ok', 'X-Door' => 'open')->{result};
ok(!$r->{isError}, 'past both, the operation runs');

done_testing;

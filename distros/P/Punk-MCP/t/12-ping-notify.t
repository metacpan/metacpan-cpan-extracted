#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPRpc;

# ---- ping -----------------------------------------------------------------------

my ($s, $r) = rpc({}, req(1, 'ping'));
is($s, 200, 'ping is 200');
is_deeply($r, { jsonrpc => '2.0', id => 1, result => {} }, 'ping answers {}');
($s, $r) = rpc({}, req('p-1', 'ping'));
is($r->{id}, 'p-1', 'with a string id too');

# ---- notifications ----------------------------------------------------------------

my ($st, $bytes, $agreed, $cancelled) = rpc_raw({}, note('notifications/initialized'));
is($st, 202, 'notifications/initialized is 202');
ok(!defined $bytes, 'with no body');

($st, $bytes, $agreed, $cancelled) =
    rpc_raw({}, note('notifications/cancelled', { requestId => 7, reason => 'x' }));
is($st, 202, 'notifications/cancelled is 202');
ok(!defined $bytes, 'with no body');
is($cancelled, 7, 'and the transport is told which request');

(undef, undef, undef, $cancelled) =
    rpc_raw({}, note('notifications/cancelled', { requestId => 'r-7' }));
is($cancelled, 'r-7', 'a string requestId too');

(undef, undef, undef, $cancelled) =
    rpc_raw({}, note('notifications/cancelled', { requestId => 1.5 }));
ok(!defined $cancelled, 'a requestId that could not be an id is ignored');

(undef, undef, undef, $cancelled) = rpc_raw({}, note('notifications/cancelled'));
ok(!defined $cancelled, 'and so is a missing one');

for my $m ('notifications/unknown', 'ping', 'initialize', 'no/such/method') {
    ($st, $bytes) = rpc_raw({}, note($m));
    is($st, 202, "a notification '$m' is 202");
    ok(!defined $bytes, "and is never answered, not even with an error");
}

# ---- responses -----------------------------------------------------------------------

for my $case (
    [ 'a result',  '{"jsonrpc":"2.0","id":4,"result":{}}' ],
    [ 'an error',  '{"jsonrpc":"2.0","id":4,"error":{"code":-1,"message":"x"}}' ],
) {
    my ($name, $msg) = @$case;
    ($st, $bytes) = rpc_raw({}, $msg);
    is($st, 202, "a response carrying $name is 202");
    ok(!defined $bytes, 'and gets no body');
}
($st, $bytes) = rpc_raw({}, '{"jsonrpc":"2.0","result":{}}');
is($st, 400, 'a response with no id is invalid');

# ---- the method table ------------------------------------------------------------------

my @names = Punk::Plugin::MCP::_methods();
my @sorted = sort { length($a) <=> length($b) || $a cmp $b } @names;
is_deeply(\@names, \@sorted, 'the table is sorted by length, then by bytes');
my %seen;
is(scalar(grep { !$seen{$_}++ } @names), scalar @names, 'with no duplicates');
ok(Punk::Plugin::MCP::_method_found($_), "$_ is found by the search") for @names;
ok(!Punk::Plugin::MCP::_method_found($_), "$_ is not") for qw(tools/lis tools/listx pong);

done_testing;

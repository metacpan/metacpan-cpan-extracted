# Tests: sessioncache

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

# cpantester: strawberry perl defaults to JSON::PP and has blessing problem with JSON::true objects
BEGIN { $ENV{PERL_JSON_BACKEND} = 'JSON::backportPP' if ($^O eq 'MSWin32'); }

use Test::More;
use JSON;
use Data::Dumper;
use Time::HiRes qw(time);
use POSIX qw(strftime);
use RPC::Switch::Client::Tiny::SessionCache;

plan tests => 7;

# test session expire list
#
my $cache = RPC::Switch::Client::Tiny::SessionCache->new();

foreach my $v (3, 4, 4, 7, 5, 6, 4, 8, 2, 4, 4, 1, 4, 4, 4) {
	my $session = {id => "SESS$v", expiretime => $v};
	$cache->expire_insert($session);
}
my $res = join(' ', map { $_->{expiretime} } @{$cache->{expiring}});
$cache->expire_regenerate($cache->{expiring});
my $want = join(' ', map { $_->{expiretime} } @{$cache->{expiring}});
is($res, $want, "test session expire list");

# test session cache
#
sub trace_cb {
	my ($type, $msg) = @_;
	printf "%s: %s\n", $type, to_json($msg, {pretty => 0, canonical => 1});
}

$cache = RPC::Switch::Client::Tiny::SessionCache->new(trace_cb => \&trace_cb);

my $expires = strftime('%Y-%m-%dT%H:%M:%SZ', gmtime(time()+1));
my $session = $cache->session_new({id => '123', expires => $expires});
my $child = {pid => $$, id => '1', start => time(), session => $session};

$res = $cache->session_put($child);
isnt($res, undef, "test session cache put");

my $lru = join(' ', map { $_->{id} } @{$cache->lru_list()});
is($lru, $child->{id}, "test session cache lru");

$child = $cache->session_get($session->{id});
isnt($child, undef, "test session cache get");

# test session lru
#
$cache = RPC::Switch::Client::Tiny::SessionCache->new(trace_cb => \&trace_cb, max_session => 3);
my @removed = ();

foreach my $v (1, 2, 3, 4, 5) {
	my $session = $cache->session_new({id => "SESS$v"});
	my $child = {pid => $$, id => $v, start => time(), session => $session};
	if ($cache->session_put($child)) {
		my $cnt = scalar keys %{$cache->{active}};
		if ($cnt > $cache->{max_session}) {
			if ($child = $cache->lru_dequeue()) {
				push(@removed, $child);
			}
		}
	}
}

$lru = join(' ', map { $_->{id} } @{$cache->lru_list()});
is($lru, '3 4 5', "test session lru");

my $rem = join(' ', map { $_->{id} } @removed);
is($rem, '1 2', "test session lru removed");

# test session per_user
#
$cache = RPC::Switch::Client::Tiny::SessionCache->new(trace_cb => \&trace_cb, max_session => 4, max_user_session => 2);
@removed = ();

foreach my $v (1, 2, 3, 4) {
	my $session = $cache->session_new({id => "SESS$v", user => "user1"});
	my $child = {pid => $$, id => $v, start => time(), session => $session};
	if ($cache->session_put($child)) {
		my $cnt = scalar keys %{$cache->{active}};
		if ($cnt > $cache->{max_session}) {
			if ($child = $cache->lru_dequeue()) {
				push(@removed, $child);
			}
		}
	}
}

my $active = join(' ', sort keys %{$cache->{active}});
is($active, 'SESS1 SESS2', "test session per user");


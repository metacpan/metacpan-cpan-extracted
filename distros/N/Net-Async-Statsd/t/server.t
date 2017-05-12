use strict;
use warnings;

use Test::More;
use Test::Fatal;
use List::Util qw(sum0);

use IO::Async::Loop;
use Net::Async::Statsd::Server;

my $loop = IO::Async::Loop->new;
my $srv = new_ok('Net::Async::Statsd::Server', [
	port => 0
]);
is(exception {
	$loop->add($srv);
}, undef, 'can add server to loop');
is(exception {
	Future->needs_any(
		$srv->listening,
		$loop->timeout_future(after => 5)
	)->get;
}, undef, 'starts listening within 5s');
note "Server port is " . $srv->port;

my %pending;
for(qw(count gauge timing)) {
	my $type = $_;
	$srv->bus->subscribe_to_event(
		$type => sub {
			my ($ev, $k, $v) = @_;
			my $next = shift @{$pending{$type}} or fail('had unexpected event');
			is($k, $next->{key}, "key $k matches expected");
			is($v, $next->{value}, "value $v matches expected");
		}
	);
}

my $cli = IO::Socket::IP->new(
	Proto    => 'udp',
	PeerAddr => '127.0.0.1',
	PeerPort => $srv->port,
) or die "no client - $!";

push @{$pending{count}}, {
	key   => 'some.test.key',
	value => 1,
};
$cli->send('some.test.key:1|c', 0) or die $!;

push @{$pending{timing}}, {
	key   => 'time.value',
	value => 123,
};
$cli->send('time.value:123|ms', 0) or die $!;

push @{$pending{gauge}}, {
	key   => 'a.gauge',
	value => 83789,
};
$cli->send('a.gauge:83789|g', 0) or die $!;

$loop->timeout_future(after => 5)->on_fail(sub {
	fail("took too long, giving up");
	note explain \%pending;
	%pending = ();
});
$loop->loop_once until 0 == sum0 map scalar(@$_), values %pending;
done_testing;


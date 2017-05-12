use strict;
use warnings;

use Test::More;
use Test::Fatal;
use List::Util qw(sum0);

use IO::Async::Loop;
use Net::Async::Statsd::Client;
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

my $cli = new_ok('Net::Async::Statsd::Client', [
	host => '127.0.0.1',
	port => $srv->port,
]);
is(exception {
	$loop->add($cli);
}, undef, 'can add client to loop');

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

{
	my @client_pending;
	for(
		{ key => 'test.gauge', value => 1234, type => 'gauge' },
		{ key => 'test.count', value => 5, type => 'count' },
		{ key => 'test.timing', value => 310879, type => 'timing' },
	) {
		my $method = $_->{type};
		push @{$pending{$method}}, {
			key   => $_->{key},
			value => $_->{value},
		};
		push @client_pending, $cli->$method($_->{key} => $_->{value});
	}
	Future->needs_all(
		@client_pending
	)->get;
}

$loop->timeout_future(after => 5)->on_fail(sub {
	fail("took too long, giving up");
	note explain \%pending;
	%pending = ();
});
$loop->loop_once until 0 == sum0 map scalar(@$_), values %pending;
done_testing;


#!perl -T

use 5.008;
use strict;
use warnings 'all';

use HTTP::Response;
use HTTP::Status 5.817 qw(:constants);
use Test::More 0.82;
use Test::MockObject;

plan tests => 7;

# Create a mock LWP::UserAgent
my $fake_ua = Test::MockObject->new;
$fake_ua->set_isa('LWP::UserAgent');

use Nagios::Plugin::OverHTTP;

$fake_ua->mock('request', sub {
	my ($self, $request) = @_;

	my $time_start = time;

	# Change URL to everything after last /
	my ($url) = $request->uri =~ m{/ (\w+) \z}msx;
	my $res;

	if ($url =~ m{_time_(\d+)\z}msx) {
		$time_start -= $1;
		$res = HTTP::Response->new(200, 'Some status', undef, 'OK - I am some result');
	}
	else {
		$res = HTTP::Response->new(404, 'Not Found');
	}

	if (time - $time_start > $self->timeout) {
		$res = HTTP::Response->new(500, 'read timeout', undef, '500 read timeout');
	}

	return $res;
});
$fake_ua->mock('timeout', sub {
	my ($self, $timeout) = @_;

	my $old_timeout = $self->{timeout} || 180;

	if (defined $timeout) {
		$self->{timeout} = $timeout;
	}

	return $old_timeout;
});

my $plugin = new_ok('Nagios::Plugin::OverHTTP' => [
	url => 'http://example.net/nagios/check_nonexistant',
	useragent => $fake_ua,
]);

###########################################################################
# TIMEOUT TESTS
isnt($plugin->has_timeout, 1, 'Has not timeout yet');
$plugin->timeout(10);
is($plugin->has_timeout, 1, 'Has timeout');
is($plugin->timeout, 10, 'Timeout set');
$plugin->url('http://example.net/nagios/check_time_15');
is($plugin->status, 2, 'Timeout should be CRITICAL');
$plugin->url('http://example.net/nagios/check_time_6');
is($plugin->status, 0, 'Timeout did not occur');
$plugin->clear_timeout;
isnt($plugin->has_timeout, 1, 'Timeout cleared');

exit 0;

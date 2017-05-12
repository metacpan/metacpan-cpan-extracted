#!perl -T

use 5.008;
use strict;
use warnings 'all';

use HTTP::Response;
use HTTP::Status 5.817 qw(:constants);
use Test::More 0.82;
use Test::MockObject;

# Create a mock LWP::UserAgent
my $fake_ua = Test::MockObject->new;
$fake_ua->set_isa('LWP::UserAgent');

use Nagios::Plugin::OverHTTP;

my %test = (
	'simple_critical' => {
		description => 'Simple time perf critical',
		body        => 'OK - I am simple | time=4s',
		status      => $Nagios::Plugin::OverHTTP::STATUS_CRITICAL,
		opts        => [critical => {time => 2}],
	},
	'simple_warning' => {
		description => 'Simple time perf warning',
		body        => 'OK - I am simple | time=4s',
		status      => $Nagios::Plugin::OverHTTP::STATUS_WARNING,
		opts        => [warning => {time => 2}],
	},
	'simple_both' => {
		description => 'Simple time perf both',
		body        => 'OK - I am simple | time=4s',
		status      => $Nagios::Plugin::OverHTTP::STATUS_WARNING,
		opts        => [critical => {time => 5}, warning => {time => 2}],
	},
	'simple_both_2' => {
		description => 'Simple time perf both 2',
		body        => 'OK - I am simple | time=4s',
		status      => $Nagios::Plugin::OverHTTP::STATUS_CRITICAL,
		opts        => [critical => {time => 3}, warning => {time => 2}],
	},
	'long_warn' => {
		description => 'Long detect',
		body        => "OK - I am long | time=4s\nstuff\nstuff\ntest | other=2\nlast=55",
		status      => $Nagios::Plugin::OverHTTP::STATUS_CRITICAL,
		opts        => [critical => {last => 3}, warning => {time => 2}],
	},
);

plan tests => 2 * keys %test;

$fake_ua->mock('request', sub {
	my ($self, $request) = @_;

	# Change URL to everything after last /
	my ($url) = $request->uri =~ m{/ (\w+) \z}msx;

	# Get the test
	my $test = $test{sprintf('%s_%s', $request->method, $url)} || $test{$url};

	if (defined $test) {
		my $http_status = $test->{http_status} || HTTP_OK;
		my $http_body   = $test->{http_body  } || $test->{body};

		# Construct a response
		my $response = HTTP::Response->new(
			$http_status,
			HTTP::Status::status_message($http_status),
			undef,
			$http_body,
		);

		if (exists $test->{http_headers}) {
			foreach my $header (@{ $test->{http_headers} }) {
				# Set the header in the response
				$response->headers->push_header(@{$header});
			}
		}

		return $response;
	}
	else {
		return HTTP::Response->new(404, 'Not Found');
	}
});
$fake_ua->mock('timeout', sub {
	my ($self, $timeout) = @_;

	my $old_timeout = $self->{timeout} || 180;

	if (defined $timeout) {
		$self->{timeout} = $timeout;
	}

	return $old_timeout;
});

###########################################################################
# CHECK
foreach my $test_url (sort keys %test) {
	my $plugin = new_ok('Nagios::Plugin::OverHTTP' => [
		url => "http://example.net/$test_url",
		useragent => $fake_ua,
		@{$test{$test_url}->{opts} || []},
	]);

	# Check the URL
	check_url(
		$plugin,
		$test{$test_url}->{status},
		$test{$test_url}->{description},
	);
}

exit 0;

sub check_url {
	my ($plugin, $status, $name) = @_;

	# Make sure it was changed
	is   $plugin->status, $status, "$name: Status is correct";

	return;
}

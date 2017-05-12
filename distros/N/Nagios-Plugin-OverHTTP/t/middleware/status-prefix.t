#!perl -T

use 5.008;
use strict;
use warnings 'all';

use Test::More 0.94;
use Test::Exception;

if ($Test::More::VERSION =~ m{\A 2\.00 0[67] \z}mosx) {
	plan skip_all => 'subtests broken with Test::More 2.00_06 and _07';
	exit 0;
}

plan tests => 3;

use HTTP::Response;
use Nagios::Plugin::OverHTTP::Middleware::StatusPrefix;
use Nagios::Plugin::OverHTTP::Response;

# Short-hand
my $middleware_class = 'Nagios::Plugin::OverHTTP::Middleware::StatusPrefix';

###########################################################################
# BASIC NEW TESTS
subtest 'New tests' => sub {
	plan tests => 1;

	# New ok with some arguments
	my $mw = new_ok $middleware_class => [
		plugin_name => q{TEST},
	];
};

###########################################################################
# REWRITE NOTHING
subtest 'Rewrite nothing' => sub {
	plan tests => 4;

	# New middleware
	my $mw = $middleware_class->new(plugin_name => 'TEST');

	# Base response
	my $response = Nagios::Plugin::OverHTTP::Response->new(
		message  => 'Test',
		response => HTTP::Response->new,
		status   => 0,
	);

	is $mw->rewrite($response->clone(message => 'PLUGIN OK - Test'))->message,
		'PLUGIN OK - Test', 'Name and status (OK) already present';
	is $mw->rewrite($response->clone(message => 'PLUGIN WARNING - Test'))->message,
		'PLUGIN WARNING - Test', 'Name and status (WARNING) already present';
	is $mw->rewrite($response->clone(message => 'MY PLUGIN OK - Test'))->message,
		'MY PLUGIN OK - Test', 'Multi-word name and status already present';
	is $mw->rewrite($response->clone(message => 'MY PLUGIN #2 OK - Test'))->message,
		'MY PLUGIN #2 OK - Test', 'Multi-word name with symbols and status already present';
};

###########################################################################
# REWRITE
subtest 'Rewrite' => sub {
	plan tests => 3;

	# New middleware
	my $mw = $middleware_class->new(plugin_name => 'TEST');

	# Base response
	my $response = Nagios::Plugin::OverHTTP::Response->new(
		message  => 'Test',
		response => HTTP::Response->new,
		status   => 0,
	);

	is $mw->rewrite($response)->message,
		'TEST OK - Test', 'Name and status (OK) added';
	is $mw->rewrite($response->clone(status => 'UNKNOWN'))->message,
		'TEST UNKNOWN - Test', 'Name and status (UNKNOWN) added';

	# Change plugin name to lowercase
	$mw->plugin_name('test');

	is $mw->rewrite($response)->message,
		'TEST OK - Test', 'Name added in uppercase';
};

exit 0;

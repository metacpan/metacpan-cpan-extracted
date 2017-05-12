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

plan tests => 4;

use HTTP::Response;
use Nagios::Plugin::OverHTTP::Middleware::PerformanceData;
use Nagios::Plugin::OverHTTP::Response;

# Short-hand
my $middleware_class = 'Nagios::Plugin::OverHTTP::Middleware::PerformanceData';

###########################################################################
# BASIC NEW TESTS
subtest 'New tests' => sub {
	plan tests => 1;

	# New ok with some arguments
	my $mw = new_ok $middleware_class => [
		honor_remote_thresholds => 1,
	];
};

###########################################################################
# REWRITE NOTHING
subtest 'Rewrite nothing' => sub {
	plan tests => 2;

	subtest 'No performance data' => sub {
		plan tests => 4;

		my $resp = Nagios::Plugin::OverHTTP::Response->new(
			message  => 'Test',
			response => HTTP::Response->new,
			status   => 0,
		);

		my $new_resp = Nagios::Plugin::OverHTTP::Middleware::PerformanceData
			->new->rewrite($resp);

		ok !$new_resp->has_performance_data, 'Response does not have performance data';
		is $new_resp->message, $resp->message, 'Response message same';
		is $new_resp->status, $resp->status, 'Response status same';
		is $new_resp, $resp, 'Response same object';
	};

	subtest 'With performance data' => sub {
		plan tests => 5;

		my $resp = Nagios::Plugin::OverHTTP::Response->new(
			message  => 'Test',
			performance_data => qq{test=3%;;; time=4s;1;1;;\nother=5},
			response => HTTP::Response->new,
			status   => 0,
		);

		my $new_resp = Nagios::Plugin::OverHTTP::Middleware::PerformanceData
			->new(rewrite_in_overrides => 0)->rewrite($resp);

		ok $new_resp->has_performance_data, 'Response has performance data';
		is $new_resp->performance_data, $resp->performance_data, 'Performance data same';
		is $new_resp->message, $resp->message, 'Response message same';
		is $new_resp->status, $resp->status, 'Response status same';
		isnt $new_resp, $resp, 'Response different object';
	};
};

###########################################################################
# REWRITE NOTHING
subtest 'Override status' => sub {
	plan tests => 3;

	subtest 'Override critical' => sub {
		plan tests => 2;

		my $resp = Nagios::Plugin::OverHTTP::Response->new(
			message  => 'Test',
			performance_data => qq{test=3%;;; time=4s;1;1;;\nother=5},
			response => HTTP::Response->new,
			status   => 0,
		);

		my $new_resp = Nagios::Plugin::OverHTTP::Middleware::PerformanceData
			->new(critical_override => {other => 4})->rewrite($resp);

		is $new_resp->status, 2, 'Response changed to critical';
		like $new_resp->performance_data, qr{'other'=5;;4}msx, 'Performance override added';
	};

	subtest 'Override warning' => sub {
		plan tests => 2;

		my $resp = Nagios::Plugin::OverHTTP::Response->new(
			message  => 'Test',
			performance_data => qq{test=3%;;; time=4s;1;1;;\nother=5},
			response => HTTP::Response->new,
			status   => 0,
		);

		my $new_resp = Nagios::Plugin::OverHTTP::Middleware::PerformanceData
			->new(warning_override => {other => 4})->rewrite($resp);

		is $new_resp->status, 1, 'Response changed to warning';
		like $new_resp->performance_data, qr{'other'=5;4}msx, 'Performance override added';
	};

	subtest 'Override warning no downgrade' => sub {
		plan tests => 2;

		my $resp = Nagios::Plugin::OverHTTP::Response->new(
			message  => 'Test',
			performance_data => qq{test=3%;;; time=4s;1;1;;\nother=5},
			response => HTTP::Response->new,
			status   => 2,
		);

		my $new_resp = Nagios::Plugin::OverHTTP::Middleware::PerformanceData
			->new(warning_override => {other => 4})->rewrite($resp);

		is $new_resp->status, 2, 'Response still critical';
		like $new_resp->performance_data, qr{'other'=5;4}msx, 'Performance override added';
	};
};

###########################################################################
# ISSUES
subtest 'Issues' => sub {
	plan tests => 1;

	subtest 'Invalid performance string' => sub {
		plan tests => 1;

		my $resp = Nagios::Plugin::OverHTTP::Response->new(
			message  => 'Test',
			performance_data => qq{'test'=3% 'time'=4s;1;1\n'other'=5 hai::},
			response => HTTP::Response->new,
			status   => 2,
		);

		my $new_resp = Nagios::Plugin::OverHTTP::Middleware::PerformanceData
			->new(rewrite_in_overrides => 1)->rewrite($resp);

		is $new_resp->performance_data, $resp->performance_data, 'Invalid silently skipped';
	};
};

exit 0;

#!perl -T
# This test represents the way Ovid has suggested
# http://use.perl.org/~Ovid/journal/39859
# but modified to use Test::More instead of Test::Most

use strict;
use warnings 'all';

use Test::More;

diag(sprintf 'Perl %s', $]);

eval {
	use Moose ();
	use Class::MOP ();

	diag(sprintf 'Moose %s', $Moose::VERSION);
	diag(sprintf 'Class::MOP %s', $Class::MOP::VERSION);
};

BEGIN {
	my @modules = qw(
		Nagios::Plugin::OverHTTP
		Nagios::Plugin::OverHTTP::Formatter
		Nagios::Plugin::OverHTTP::Formatter::Nagios::Auto
		Nagios::Plugin::OverHTTP::Formatter::Nagios::Version2
		Nagios::Plugin::OverHTTP::Formatter::Nagios::Version3
		Nagios::Plugin::OverHTTP::Library
		Nagios::Plugin::OverHTTP::Middleware
		Nagios::Plugin::OverHTTP::Middleware::PerformanceData
		Nagios::Plugin::OverHTTP::Middleware::StatusPrefix
		Nagios::Plugin::OverHTTP::Parser
		Nagios::Plugin::OverHTTP::Parser::Standard
		Nagios::Plugin::OverHTTP::PerformanceData
		Nagios::Plugin::OverHTTP::Response
	);

	# Plan tests of the number of modules
	plan tests => scalar @modules;

	# Attempt to use every module
	foreach my $module (@modules) {
		use_ok($module) or BAIL_OUT("Unable to load $module");
	}
}

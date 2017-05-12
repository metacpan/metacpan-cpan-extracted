#!/usr/bin/env perl

use 5.008;
use strict;
use warnings 'all';

# TEST MODULES
use Test::More;

# Modules in this distribution
my @module = qw(
	Net::SAJAX
	Net::SAJAX::Exception
	Net::SAJAX::Exception::JavaScriptConversion
	Net::SAJAX::Exception::JavaScriptEvaluation
	Net::SAJAX::Exception::MethodArguments
	Net::SAJAX::Exception::RemoteError
	Net::SAJAX::Exception::Response
);

# Modules to print the version number of
my @display = qw(
	Moose
	Class::MOP
);

# Show perl version in test output
diag(sprintf 'Perl %s', $]);

for my $module (@display) {
	my $version = eval qq{require $module; \$${module}::VERSION};
	diag($@ ? $@ : "$module $version");
}

# Plan the tests for the number of modules
plan tests => scalar @module;

for my $module (@module) {
	use_ok($module) or BAIL_OUT("Unable to load $module");
}

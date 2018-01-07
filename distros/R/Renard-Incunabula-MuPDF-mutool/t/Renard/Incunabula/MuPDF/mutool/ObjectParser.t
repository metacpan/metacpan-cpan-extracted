#!/usr/bin/env perl

use Test::Most tests => 2;

use Renard::Incunabula::Common::Setup;
use Renard::Incunabula::MuPDF::mutool::ObjectParser;

subtest "Unsecape" => sub {
	my @tests = (
		{ input => q(\0053), output => "\005" ."3" },
		{ input => q(\053), output => "+" },
		{ input => q(\53), output => "+" },
	);

	plan tests => 0+@tests;

	for my $test (@tests) {
		is(
			Renard::Incunabula::MuPDF::mutool::ObjectParser->unescape( $test->{input} ),
			$test->{output},
			"unescape @{[ $test->{input} ]}"
		);
	}
};

subtest "Boolean" => sub {
	my @tests = (
		{ input => q(/True), output => 1 },
		{ input => q(/False), output => 0  },
	);

	plan tests => 0+@tests;

	for my $test (@tests) {
		my $parse = Renard::Incunabula::MuPDF::mutool::ObjectParser->new(
			filename => __FILE__,
			string => $test->{input}, is_toplevel => 0
		);
		subtest "Input @{[ $test->{input} ]}" => sub  {
			ok( $test->{output} ? $parse->data : ! $parse->data, "Correct parsing of boolean" );
			is( $parse->type, Renard::Incunabula::MuPDF::mutool::ObjectParser->TypeBoolean, 'Is tagged as Boolean type' );
		}
	}
};

done_testing;

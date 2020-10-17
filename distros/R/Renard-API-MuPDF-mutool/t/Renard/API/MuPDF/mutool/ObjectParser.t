#!/usr/bin/env perl

use utf8;
use Test::Most tests => 3;

use Renard::Incunabula::Common::Setup;
use Renard::API::MuPDF::mutool::ObjectParser;

subtest "Unsecape" => sub {
	my @tests = (
		{ input => q(\0053), output => "\005" ."3" },
		{ input => q(\053), output => "+" },
		{ input => q(\53), output => "+" },
	);

	plan tests => 0+@tests;

	for my $test (@tests) {
		is(
			Renard::API::MuPDF::mutool::ObjectParser->unescape_ascii_string( $test->{input} ),
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
		my $parse = Renard::API::MuPDF::mutool::ObjectParser->new(
			filename => __FILE__,
			string => $test->{input}, is_toplevel => 0
		);
		subtest "Input @{[ $test->{input} ]}" => sub  {
			ok( $test->{output} ? $parse->data : ! $parse->data, "Correct parsing of boolean" );
			is( $parse->type, Renard::API::MuPDF::mutool::ObjectParser->TypeBoolean, 'Is tagged as Boolean type' );
		}
	}
};

subtest "Decode hex UTF-16BE" => sub {
	my @tests = (
		{
			input => 'FEFF004D006900630072006F0073006F0066007400AE00200050006F0077006500720050006F0069006E007400AE00200032003000310030',
			output => 'Microsoft® PowerPoint® 2010',
		},
		{
			# with spaces
			input => 'FE FF 00 4D 006900630072006F0073006F0066007400AE00200050006F0077006500720050006F0069006E007400AE00200032003000310030',
			output => 'Microsoft® PowerPoint® 2010',
		},
	);

	for my $test (@tests) {
		binmode STDOUT, ':encoding(UTF-8)';
		binmode STDERR, ':encoding(UTF-8)';
		is(
			Renard::API::MuPDF::mutool::ObjectParser->decode_hex_utf16be( $test->{input} ),
			$test->{output},
			"UTF-16BE decode @{[ $test->{input} ]}"
		);
	}
};

done_testing;

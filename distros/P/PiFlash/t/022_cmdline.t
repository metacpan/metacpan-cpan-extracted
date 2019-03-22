#!/usr/bin/perl
# 022_cmdline.t - tests for PiFlash command line option processing

use strict;
use warnings;
use autodie;
use Test::More;
use File::Basename;
use PiFlash;
use PiFlash::State;
use Data::Dumper;

# detect debug mode from environment
# run as "DEBUG=1 perl -Ilib t/022_cmdline.t" to get debug output to STDERR
my $debug_mode = exists $ENV{DEBUG};

# initialize program state storage
my @top_level_params = PiFlash::state_categories();

# initial ordered tests for each case
my %ordered_tests = (
	result => sub {
		my ($test_set_str, $expected, $value) = @_;
		is($value, $expected, "$test_set_str ".($expected ? "successful result" : "expected failure"));
	},
	exception => sub {
		my ($test_set_str, $expected, $value) = @_;
		ok($value =~ $expected, "$test_set_str expected exception: $expected");
	},
);

# evaluate expression on state data after running test case
sub state_expr
{
	my $test_key = shift;
	my $expr_desc = shift;

	if (ref $expr_desc ne "HASH") {
		BAIL_OUT("invalid test: expression description must be a hash - got a "
			.((ref $expr_desc eq "") ? "scalar" : ref $expr_desc));
	}
	my $path = $expr_desc->{path};
	my $op = $expr_desc->{op};
	my $expect = $expr_desc->{expect} // "";

	# find the state data by path
	my $description = join("/", @$path)." $op $expect";
	$debug_mode and print STDERR "debug state_expr $description\n";
	my $top_level_param = shift @$path;
	my $pos = PiFlash::State->accessor($top_level_param);
	foreach my $key (@$path) {
		if (ref $pos eq "HASH" and exists $pos->{$key}) {
			$pos = $pos->{$key};
		} else {
			$debug_mode and say STDERR "debug state_expr: $key not found in ".join("/", $top_level_param, @$path);
			return ($description, 0);
		}
	}

	# run the expression
	my $result;
	$debug_mode and print STDERR "debug state_expr pos=".((defined $pos) ? Dumper($pos) : "undef\n");
	if ($op eq "has") {
		$result = (ref $pos eq "HASH" and exists $pos->{$expect});
	} elsif ($op eq "hasnt") {
		$result = (ref $pos ne "HASH" or not exists $pos->{$expect});
	} elsif ($op eq "eq") {
		$result = $pos eq $expect;
	} elsif ($op eq "ne") {
		$result = $pos ne $expect;
	} elsif ($op eq "le") {
		$result = $pos le $expect;
	} elsif ($op eq "ge") {
		$result = $pos ge $expect;
	} elsif ($op eq "==") {
		$result = $pos == $expect;
	} elsif ($op eq "!=") {
		$result = $pos != $expect;
	} elsif ($op eq "<=") {
		$result = $pos <= $expect;
	} elsif ($op eq ">=") {
		$result = $pos >= $expect;
	} elsif ($op eq "empty") {
		$result = (ref $pos eq "HASH" and scalar (keys %$pos) == 0);
	} else {
		BAIL_OUT("invalid test: unrecognized expression operation $op");
	}
	return ($description, $result);
}

# function with tests to run on command line options, verifying contents of saved state data
sub cmdline_tests
{
	my $test_set_str = shift;
	my $cmdline = shift;
	my $tests = shift;

	# set up for test - clear state, set CLI params
	undef $PiFlash::State::state;
	PiFlash::State->init(@top_level_params);

	# run command line test case
	my %values;
	eval { PiFlash::process_cli($cmdline); };
	$values{exception} = $@;
	$values{result} = ($values{exception} ? 0 : 1); # true if no exceptions
	if ($debug_mode) {
		if (not $values{result}) {
			print STDERR "debug cmdline_tests $test_set_str values ".Dumper(\%values);
		}
		print STDERR "debug cmdline_tests $test_set_str: cmdline = ".join(" ", @$cmdline)."\n";
		print STDERR "debug cmdline_tests $test_set_str: ".Dumper($PiFlash::State::state);
	}

	# use command line results for tests

	# run initial ordered tests first, if they exist in the test list
	my %tests_done;
	foreach my $test_key (qw(result exception)) {
		if (exists $tests->{$test_key}) {
			$ordered_tests{$test_key}->($test_set_str, $tests->{$test_key}, $values{$test_key});
			$tests_done{$test_key} = 1;
		}
	}

	# then run remaining unordered tests in alphabetical order
	foreach my $test_key (sort keys %$tests) {
		exists $tests_done{$test_key} and next;
		if ($test_key =~ /^data[0-9]+$/) {
			my ($description, $is_ok) = state_expr($test_key, $tests->{$test_key});
			ok($is_ok, "$test_set_str/$test_key $description");
		} else {
			BAIL_OUT("invalid test: $test_set_str unrecognized test name: $test_key");
		}
	}
}

# command line test cases
my $input_dir = "t/test-inputs/".basename($0, ".t");
my $filename_that_exists = $input_dir."/a_file_that_exists";
my $filename_that_doesnt_exist = $input_dir."/a_file_that_doesnt_exist";
my @test_cases = (
	[
		[ ],
		{
			result => 0,
			exception => 'missing argument',
			data00 => { path => [qw(cli_opt)], op => "empty" },
			data01 => { path => [qw(config)], op => "empty" },
			data02 => { path => [qw(hook)], op => "empty" },
			data03 => { path => [qw(input)], op => "empty" },
			data04 => { path => [qw(log)], op => "empty" },
			data05 => { path => [qw(output)], op => "empty" },
			data06 => { path => [qw(plugin)], op => "empty" },
			data07 => { path => [qw(system)], op => "empty" },
		}
	],
	[
		[ "--version" ],
		{
			result => 1,
			data00 => { path => [qw(cli_opt)], op => "has", expect => "version" },
			data01 => { path => [qw(cli_opt version)], op => "==", expect => 1 },
		}
	],
	[
		[ "--sdsearch" ],
		{
			result => 1,
			data00 => { path => [qw(cli_opt)], op => "has", expect => "sdsearch" },
			data01 => { path => [qw(cli_opt sdsearch)], op => "==", expect => 1 },
		}
	],
	[
		[ "--help" ],
		{
			result => 1,
			data00 => { path => [qw(cli_opt)], op => "has", expect => "help" },
			data01 => { path => [qw(cli_opt help)], op => "==", expect => 1 },
		}
	],
	[
		[ "--foo" ],
		{
			result => 0,
			exception => 'Unknown option: foo',
			data00 => { path => [qw(cli_opt)], op => "hasnt", expect => "foo" },
		}
	],
	[
		[ "--test", "skip_block_check=1", $filename_that_exists, $filename_that_doesnt_exist ],
		{
			result => 1,
			data00 => { path => [qw(cli_opt)], op => "has", expect => "test" },
			data01 => { path => [qw(cli_opt test)], op => "has", expect => "skip_block_check" },
			data02 => { path => [qw(cli_opt test skip_block_check)], op => "==", expect => 1 },
		}
	],
	[
		[ $filename_that_exists, $filename_that_doesnt_exist, "--test", "skip_block_check=1" ],
		{
			result => 1,
			data00 => { path => [qw(cli_opt)], op => "has", expect => "test" },
			data01 => { path => [qw(cli_opt test)], op => "has", expect => "skip_block_check" },
			data02 => { path => [qw(cli_opt test skip_block_check)], op => "==", expect => 1 },
		}
	],
	[
		[ "--test", "skip_block_check=1", $filename_that_doesnt_exist, $filename_that_doesnt_exist ],
		{
			result => 0,
			exception => 'source file.*does not exist',
			data00 => { path => [qw(cli_opt)], op => "has", expect => "test" },
			data01 => { path => [qw(cli_opt test)], op => "has", expect => "skip_block_check" },
			data02 => { path => [qw(cli_opt test skip_block_check)], op => "==", expect => 1 },
		}
	],
	[
		[ $filename_that_exists, $filename_that_doesnt_exist ],
		{
			result => 0,
			exception => 'destination device.*does not exist',
			data00 => { path => [qw(cli_opt)], op => "empty" },
		}
	],
	[
		[ "--test", "skip_block_check=1", "--resize", $filename_that_exists, $filename_that_doesnt_exist ],
		{
			result => 1,
			data01 => { path => [qw(cli_opt)], op => "has", expect => "resize" },
			data02 => { path => [qw(cli_opt resize)], op => "==", expect => 1 },
		}
	],
	[
		[ "--test", "skip_block_check=1", "--config", $filename_that_exists, $filename_that_exists, $filename_that_doesnt_exist ],
		{
			result => 1,
			data00 => { path => [qw(cli_opt)], op => "has", expect => "config" },
			data01 => { path => [qw(cli_opt config)], op => "eq", expect => $filename_that_exists },
		}
	],
);

# compute number of tests:
#    n test cases
#    x tests per case
my $total_tests = 0;
foreach my $test_case (@test_cases) {
	my $tests = $test_case->[1];
	$total_tests += keys %$tests;
}
plan tests => $total_tests;

# run command-line tests
my $counter=0;
foreach my $test_case (@test_cases) {
	if (ref $test_case ne "ARRAY") {
		BAIL_OUT("test case data is not an array");
	}
	my $test_set_str = sprintf("%03d", $counter++);
	cmdline_tests($test_set_str, @$test_case);
}

1;

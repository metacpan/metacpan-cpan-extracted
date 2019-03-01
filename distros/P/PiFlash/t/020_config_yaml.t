#!/usr/bin/perl
# 020config_yaml.t - tests for YAML configuration files

use strict;
use warnings;
use autodie;
use Test::More;
use File::Basename;
use PiFlash::State;
use YAML::XS;

# detect debug mode from environment
# run as "DEBUG=1 perl -Ilib t/011PiFlash_Command.t" to get debug output to STDERR
my $debug_mode = exists $ENV{DEBUG};

# function with tests to run on each test input file
sub yaml_tests
{
	my $filepath = shift;
	my $good_yaml = shift;
	my $good_str = $good_yaml ? "good" : "bad";

	# clear config in PiFlash::State
	$PiFlash::State::state->{config} = {};

	# read the config file
	eval { PiFlash::State::read_config($filepath); };

	# run tests
	my $config = PiFlash::State::config();
	$debug_mode and warn "debug: config:\n".PiFlash::State::odump($config,0);
	if ($good_yaml) {
		is("$@", '', "$filepath 1 ($good_str): no exceptions");
		isnt(scalar keys %$config, 0, "$filepath 2 ($good_str): non-empty config");

		# direct load the config file and store it like in PiFlash::State::read_config for comparison
		# if it's a map, use it directly
		#   otherwise save it in a config element called config
		# if there are more YAML documents in the file, save them in an array ref in a config called "docs"
		my @direct_load = eval { YAML::XS::LoadFile($filepath); };
		my $doc = shift @direct_load;
		if (ref $doc ne "HASH") {
			$doc = { config => $doc };
		}
		if (@direct_load) {
			$doc->{docs} = \@direct_load;
		}
		$debug_mode and warn "debug: compare\n".PiFlash::State::odump($doc,0);
		is_deeply($config, $doc, "$filepath 3 ($good_str): content match");
	} else {
		isnt("$@", '', "$filepath 1 ($good_str): expected exception");
	}
}

# initialize program state storage
my @top_level_params = ("config");
PiFlash::State->init(@top_level_params);

# read list of test input files from subdirectory with same basename as this script
my $input_dir = "t/test-inputs/".basename($0, ".t");
if (! -d $input_dir) {
	BAIL_OUT("can't find test inputs directory: expected $input_dir");
}
opendir(my $dh, $input_dir) or BAIL_OUT("can't open $input_dir directory");
my @files = sort grep { /^[^.]/ and -f "$input_dir/$_" } readdir($dh);
closedir $dh;

# count files by good and bad YAML syntax
my $good_total = 0;
my $bad_total = 0;
foreach my $file ( @files ) {
	if ($file =~ /-bad.yml$/) {
		$bad_total++;
	} else {
		$good_total++;
	}
}

# compute number of tests: 3 tests in yaml_tests() x n test files
plan tests => 3 * $good_total + 1 * $bad_total;

# run yaml_tests() for each file
foreach my $file ( @files ) {
	# flag for good YAML formatting is set true unless filename ends in "-bad"
	my $good_yaml = 1;
	if ($file =~ /-bad.yml$/) {
		$good_yaml = 0;
	}
	yaml_tests("$input_dir/$file", $good_yaml);
}

1;

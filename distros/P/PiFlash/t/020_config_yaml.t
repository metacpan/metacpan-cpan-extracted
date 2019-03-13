#!/usr/bin/perl
# 020config_yaml.t - tests for YAML configuration files

use strict;
use warnings;
use autodie;
use Test::More;
use File::Basename;
use PiFlash::State;
use YAML::XS;
use Data::Dumper;

# detect debug mode from environment
# run as "DEBUG=1 perl -Ilib t/011PiFlash_Command.t" to get debug output to STDERR
my $debug_mode = exists $ENV{DEBUG};

# function with tests to run on each test input file
sub yaml_tests
{
	my $filepath = shift;
	my $flags = shift;
	if (!exists $flags->{bad}) {
		$flags->{good} = 1; # if not bad, add good flag so it shows up on the flag summary string
	}
	my $flag_str = join " ", sort keys %$flags;

	# clear config in PiFlash::State
	$PiFlash::State::state->{config} = {};

	# read the config file
	eval { PiFlash::State::read_config($filepath); };

	# run tests
	my $config = PiFlash::State::config();
	$debug_mode and warn "debug: config:\n".Dumper($PiFlash::State::state);
	if (!exists $flags->{bad}) {
		is("$@", '', "$filepath 1 ($flag_str): no exceptions");
		isnt(scalar keys %$config, 0, "$filepath 2 ($flag_str): non-empty config");

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
		$debug_mode and warn "debug: compare\n".Dumper($doc);
		is_deeply($config, $doc, "$filepath 3 ($flag_str): content match");

		# perform YAML document tests when table of contents (TOC) flag is enabled
		# this tests how we use YAML documents as attachments for plugins
		# these extra tests are counted in the $toc_total
		if (exists $flags->{toc} and $flags->{toc}) {
			my $toc = shift @direct_load;
			is(ref $toc, "ARRAY", "$filepath 4 ($flag_str): TOC doc is a list");

			# check if plugin-typed YAML document attachments are stored correctly by plugin name
			my $docs_ok = 1;
			my $plugin_docs = PiFlash::State::plugin("docs");
			for (my $i=0; $i < scalar @direct_load; $i++) {
				($i < scalar @$toc) or next;
				my $doc = $direct_load[$i];
				my $type = $toc->[$i]{type};
				(defined $type) or next;
				if (ref $doc eq "HASH") {
					# check if the storage for the plugin's data exists
					if (!exists $plugin_docs->{$type}) {
						$docs_ok = 0;
						$debug_mode and print STDERR "020_config_yaml.t debug: no $type in plugin_docs\n";
						last;
					}
					if (ref $plugin_docs->{$type} ne "HASH") {
						$docs_ok = 0;
						$debug_mode and print STDERR "020_config_yaml.t debug: $type not a HASH ref\n";
						last;
					}

					# for brevity we only compare keys between each source/destination set of hashes
					# so test data should use different keys for different plugins' data
					my $dest_str = join(" ", sort keys %{$plugin_docs->{$type}});
					my $src_str = join(" ", sort keys %$doc);
					if (join(" ", $dest_str ne $src_str)) {
						$docs_ok = 0;
						$debug_mode and print STDERR "020_config_yaml.t debug: ($dest_str) ne ($src_str)\n";
						last;
					}
				}
			}
			ok($docs_ok, "$filepath 5 ($flag_str): plugin docs saved by name");
		}
	} else {
		isnt("$@", '', "$filepath 1 ($flag_str): expected exception");
	}
}

# initialize program state storage
my @top_level_params = ("config", "plugin");
PiFlash::State->init(@top_level_params);

# read list of test input files from subdirectory with same basename as this script
my $input_dir = "t/test-inputs/".basename($0, ".t");
if (! -d $input_dir) {
	BAIL_OUT("can't find test inputs directory: expected $input_dir");
}
opendir(my $dh, $input_dir) or BAIL_OUT("can't open $input_dir directory");
my @files = sort grep { /^[^.]/ and -f "$input_dir/$_" } readdir($dh);
closedir $dh;

# load test metadata
my @test_metadata = YAML::XS::LoadFile("$input_dir/000-test-metadata.yml");
my $metadata;
if (ref $test_metadata[0] eq "HASH") {
	$metadata = $test_metadata[0];
}

# count files by good and bad YAML syntax
my $good_total = 0;
my $bad_total = 0;
my $toc_total = 0;
foreach my $file ( @files ) {
	my $flags = {};
	if ($metadata and exists $metadata->{$file}) {
		if (ref $metadata->{$file} eq "HASH") {
			$flags = $metadata->{$file};
		}
	}
	if (exists $flags->{bad}) {
		$bad_total++;
	} else {
		$good_total++;
		if (exists $flags->{toc}) {
			$toc_total++;
		}
	}
}

# compute number of tests: (flags are read from 000-test-metadata.yml)
#   1 test for files marked with "bad" flag
#   3 tests for files with good syntax
#   2 extra tests on files marked with the "toc" (table of contents) flag
plan tests => 1 * $bad_total + 3 * $good_total + 2 * $toc_total;

# run yaml_tests() for each file
foreach my $file ( @files ) {
	my $flags = {};
	if ($metadata and exists $metadata->{$file}) {
		if (ref $metadata->{$file} eq "HASH") {
			$flags = $metadata->{$file};
		}
	}
	yaml_tests("$input_dir/$file", $flags);
}

1;

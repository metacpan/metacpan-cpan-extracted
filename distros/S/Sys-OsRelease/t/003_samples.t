#
#===============================================================================
#         FILE: 003_samples.t
#  DESCRIPTION: test Sys::OsRelease with samples from various OS's 
#       AUTHOR: Ian Kluft (IKLUFT)
#      CREATED: 04/25/2022 09:14:30 PM
#===============================================================================

use strict;
use warnings;
use Carp qw(croak);
use File::Basename;
use File::Find;
use Cwd;
use YAML;
use Sys::OsRelease;

use Test::More; # planned test total will be counted from YAML data

# globals 
my %config;
my $input_dir = getcwd()."/t/test-inputs/".basename($0, ".t");
my $yaml_config = "test-config.yaml";

# count tests from YAML config data
if (! -d $input_dir) {
    BAIL_OUT("can't find test inputs directory: expected $input_dir");
}

if ( not -e $input_dir."/".$yaml_config) {
    BAIL_OUT("can't find test config file $input_dir/$yaml_config");
}
my $test_config = YAML::LoadFile($input_dir."/".$yaml_config);
if (not exists $test_config->{count}) {
    BAIL_OUT("can't find test count in configuration data");
}
plan tests => $test_config->{count};

# run tests in each file
foreach my $file (sort keys %{$test_config->{files}}) {
    # instantiate
    my $osrelease = Sys::OsRelease->instance(search_path => [$input_dir], file_name => $file);
    #require Data::Dumper;
    #print STDERR "osrelease: ".Data::Dumper::Dumper($osrelease);
    #print STDERR "test: ".Data::Dumper::Dumper($test_config->{files}{$file});

    # check has_attr() and get() can access the attributes
    isa_ok($osrelease, "Sys::OsRelease", "$file: instance is correct type");
    foreach my $attr (sort keys %{$test_config->{files}{$file}}) {
        ok($osrelease->has_attr($attr), "$file: found attribute $attr");
        is($osrelease->get($attr), $test_config->{files}{$file}{$attr},
            "$file: $attr => '".$test_config->{files}{$file}{$attr}."'");
    }

    # check found_attrs() method returned a list of existing attributes
    my @found_attrs = $osrelease->found_attrs;
    my $expected_attr_count = scalar keys %{$test_config->{files}{$file}};
    is(scalar @found_attrs, $expected_attr_count,
        "$file: ref->found_attrs() returned list of size $expected_attr_count");
    foreach my $found_attr (@found_attrs) {
        ok(exists $test_config->{files}{$file}{$found_attr}, "$file: ref->found_attrs contains $found_attr");
    }

    # clean up the test instance
    Sys::OsRelease->clear_instance();
}

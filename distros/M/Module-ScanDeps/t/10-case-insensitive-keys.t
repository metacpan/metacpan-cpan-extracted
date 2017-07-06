#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;

use Test::More;
BEGIN {
    if(!File::Spec->case_tolerant()) {
        plan skip_all => 'Test irrelevant on case-sensitive systems';
    } else {
        plan tests => 43;
    }
}

use lib qw(t t/data/case-insensitive-keys);
use Utils;

##############################################################
# Tests compilation of Module::ScanDeps
##############################################################
BEGIN { use_ok( 'Module::ScanDeps' ); }


##############################################################
# Static dependency check of scripts that reference the same
# module but in different cases
##############################################################
my @roots1 = qw(t/data/case-insensitive-keys/this_case.pl t/data/case-insensitive-keys/that_case.pl);
my $expected_rv1 =
{
  "Test.pm"      => {
                      file    => generic_abs_path("t/data/case-insensitive-keys/Test.pm"),
                      key     => "Test.pm",
                      type    => "module",
                      used_by => ["this_case.pl", "that_case.pl"],
                    },
  "that_case.pl" => {
                      file => generic_abs_path("t/data/case-insensitive-keys/that_case.pl"),
                      key  => "that_case.pl",
                      type => "data",
                      uses => ["Test.pm"],
                    },
  "this_case.pl" => {
                      file => generic_abs_path("t/data/case-insensitive-keys/this_case.pl"),
                      key  => "this_case.pl",
                      type => "data",
                      uses => ["Test.pm"],
                    },
};

# Functional i/f
my $rv1 = scan_deps(@roots1);
#use Data::Dumper;
#print STDERR "\n", Dumper($rv1);

compare_scandeps_rvs($rv1, $expected_rv1, \@roots1);

# Check that only one entry for Cwd is created.

my @roots2 = qw(t/data/case-insensitive-keys/Test2.pm);
my $rv2 = scan_deps(files => \@roots2);
my @keys = grep { lc($_) eq "cwd.pm" } keys %$rv2;
ok($#keys == 0, "contains only one match");

__END__

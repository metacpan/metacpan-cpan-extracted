#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use Test::More qw(no_plan); # no_plan because the number of objects in the dependency tree (and hence the number of tests) can change
use Utils;

##############################################################
# Tests compilation of Module::ScanDeps
##############################################################
BEGIN { use_ok( 'Module::ScanDeps' ); }

##############################################################
# Tests static dependency scanning on a real set of modules.
# This exercises the scanning functionality but because the
# majority of files scanned aren't fixed, the checks are
# necessarily loose.
##############################################################
my $root = $0;

my @deps = qw(
    Carp.pm   Config.pm	  Exporter.pm 
    Test/More.pm  strict.pm   vars.pm
);

# Functional i/f
my $rv = scan_deps($root);
generic_scandeps_rv_test($rv, [$0], \@deps);

__END__

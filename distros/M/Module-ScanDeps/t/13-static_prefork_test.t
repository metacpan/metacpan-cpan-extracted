#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Requires qw( prefork );

use lib 't';
use Utils;

BEGIN {
    # Mwuahahaha!
    delete $INC{"prefork.pm"};
    %prefork:: = ();

    plan 'no_plan'; # no_plan because the number of objects in the dependency tree (and hence the number of tests) can change
}

my $rv;
my $root;

##############################################################
# Tests compilation of Module::ScanDeps
##############################################################
BEGIN { use_ok( 'Module::ScanDeps' ); }

##############################################################
# Tests static dependency scanning with the prefork module.
# This was broken until Module::ScanDeps 0.85
##############################################################
$root = $0;

use prefork "less";

my @deps = qw(
    Carp.pm   Config.pm	  Exporter.pm 
    Test/More.pm  strict.pm   vars.pm
    prefork.pm less.pm
);

# Functional i/f
$rv = scan_deps($root);
generic_scandeps_rv_test($rv, [$0], \@deps);

__END__

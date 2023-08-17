#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use Test::More tests => 2;
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
my $root = "t/data/minimal.pl";

my @deps = qw( Carp.pm Exporter.pm XSLoader.pm DynaLoader.pm
               strict.pm warnings.pm Data/Dumper.pm );

# Functional i/f
my $rv = scan_deps($root);
check_rv($rv, [$root], \@deps);

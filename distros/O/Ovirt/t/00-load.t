#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use_ok( 'Ovirt' )           || print "Bail out!\n";
use_ok( 'Ovirt::VM' )       || print "Bail out!\n";
use_ok( 'Ovirt::Cluster' )  || print "Bail out!\n";
use_ok( 'Ovirt::Template' ) || print "Bail out!\n";

done_testing();

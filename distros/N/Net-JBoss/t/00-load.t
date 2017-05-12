#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use_ok( 'Net::JBoss' )               || print "Bail out!\n";
use_ok( 'Net::JBoss::Management' )   || print "Bail out!\n";

done_testing();
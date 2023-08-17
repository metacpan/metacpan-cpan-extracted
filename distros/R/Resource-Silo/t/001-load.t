#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use_ok( 'Resource::Silo' ) || print "Bail out!\n";

diag( "Testing Resource::Silo $Resource::Silo::VERSION, Perl $], $^X" );
done_testing;

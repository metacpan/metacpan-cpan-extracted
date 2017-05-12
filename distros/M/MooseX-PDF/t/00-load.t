#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::Most  tests => 1;

BEGIN {
    use_ok( 'MooseX::PDF' ) || print "Bail out!\n";
}

diag( "Testing MooseX::PDF $MooseX::PDF::VERSION, Perl $], $^X" );

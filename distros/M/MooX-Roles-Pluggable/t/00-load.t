#!perl

use 5.008003;
use strict;
use warnings FATAL => 'all';

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MooX::Roles::Pluggable' ) || print "Bail out!\n";
}

diag( "Testing MooX::Roles::Pluggable $MooX::Roles::Pluggable::VERSION, Perl $], $^X" );

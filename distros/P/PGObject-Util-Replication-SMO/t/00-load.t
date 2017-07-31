#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PGObject::Util::Replication::SMO' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Util::Replication::SMO $PGObject::Util::Replication::Master::VERSION, Perl $], $^X" );

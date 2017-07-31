#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PGObject::Util::Replication::Standby' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Util::Replication::Standby $PGObject::Util::Replication::Standby::VERSION, Perl $], $^X" );

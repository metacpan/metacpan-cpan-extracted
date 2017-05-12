#!perl -T
use strict;
use Test::More tests => 1;
use lib "t/lib";

use_ok( 'SNMP::Extension::PassPersist' );
diag( "Testing SNMP::Extension::PassPersist $SNMP::Extension::PassPersist::VERSION, Perl $], $^X" );

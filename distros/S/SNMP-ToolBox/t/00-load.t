#!perl -T
use strict;
use Test::More tests => 1;

use_ok( 'SNMP::ToolBox' ) || print "Bail out!\n";

diag( "Testing SNMP::ToolBox $SNMP::ToolBox::VERSION, Perl $], $^X" );

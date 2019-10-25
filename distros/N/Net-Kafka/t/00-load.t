#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Kafka' ) || print "Bail out!\n";
}

diag( "Testing Net::Kafka $Net::Kafka::VERSION, Perl $], $^X" );

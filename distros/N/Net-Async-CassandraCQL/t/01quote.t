#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Net::Async::CassandraCQL;

my $cass = Net::Async::CassandraCQL->new;

ok( defined $cass, 'defined $cass' );

is( $cass->quote( "hello" ),     "'hello'",       '->quote simple string' );
is( $cass->quote( "'message'" ), "'''message'''", "->quote string with 'quotes'" );

is( $cass->quote_identifier( "simple" ),       "simple",             '->quote_identifier simple' );
is( $cass->quote_identifier( "Capitals" ),     "\"Capitals\"",       '->quote_identifier Capitals' );
is( $cass->quote_identifier( "weird-chars" ),  "\"weird-chars\"",    '->quote_identifier weird-chars' );
is( $cass->quote_identifier( "with\"quotes" ), "\"with\"\"quotes\"", '->quote_identifier with"quotes' );

done_testing;

#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

use Net::LibResolv qw( res_query NS_C_IN NS_T_A );

my $answer = res_query( "www.cpan.org", NS_C_IN, NS_T_A );

ok( length($answer) > 0, 'res_query gave an answer for www.cpan.org' );

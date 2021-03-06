#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

use Net::LibResolv qw( res_search NS_C_IN NS_T_A );

my $answer = res_search( "www.cpan.org", NS_C_IN, NS_T_A );

ok( length($answer) > 0, 'res_search gave an answer for www.cpan.org' );

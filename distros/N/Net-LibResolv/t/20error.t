#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

use Net::LibResolv qw( 
   res_query NS_C_IN NS_T_A
   $h_errno HOST_NOT_FOUND
);

# Now something I hope doesn't exist - we put it in a known-missing TLD
my $missinghost = "nonexistent.local";

SKIP: {
   my $answer = res_query( $missinghost, NS_C_IN, NS_T_A );
   skip "Resolver has an answer for $missinghost IN A", 1 if defined $answer;

   cmp_ok( $h_errno, '==', HOST_NOT_FOUND, '$h_errno for missing host' );
}

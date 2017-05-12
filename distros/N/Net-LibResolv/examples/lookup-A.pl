#!/usr/bin/perl

use strict;
use warnings;

use Net::LibResolv qw( res_query NS_C_IN NS_T_A $h_errno );
use Net::DNS::Packet;

my $answer = res_query( $ARGV[0], NS_C_IN, NS_T_A );
defined $answer or die "DNS failure - $h_errno\n";

foreach my $rr ( Net::DNS::Packet->new( \$answer )->answer ) {
   print $rr->string, "\n";
}

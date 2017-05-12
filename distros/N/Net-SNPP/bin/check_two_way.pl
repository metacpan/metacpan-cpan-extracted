#!/usr/local/bin/perl -w
use strict;
use Net::SNPP;

die "I need two arguments!" if ( @ARGV != 2 );

# should be two arguments that are digits
my( $message_tag, $message_pin ) = @ARGV;

#my $snpp_server = Net::SNPP->new( 'snpp.nextel.com' );
my $snpp_server = Net::SNPP->new( 'localhost', Port => 11444 )
    || die "could not connect to SNPP server!";
#$snpp_server->debug(10);

my @status = $snpp_server->message_status( $message_tag, $message_pin );

print <<EOTXT;
   Message $message_tag $message_pin has a status of $status[4].
   Sequence number is $status[0] with timestamp $status[1]$status[2].
   The response, if any is '$status[3].'
EOTXT
$snpp_server->quit();

exit 0;

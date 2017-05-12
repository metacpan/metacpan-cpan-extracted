#!/usr/local/bin/perl -w
use strict;
use Net::SNPP;

my $pager_number = shift(@ARGV);
my $message      = join(' ', @ARGV);

die "I need a pager number and a message or this exercise is pointless."
    if ( !$pager_number || !$message );

# change this to the address for your provider's SNPP server
#my $snpp = Net::SNPP->new( 'snpp.nextel.com' );
my $snpp = Net::SNPP->new( 'localhost', Port => 11444 )
    || die "could not connect to SNPP server";
#$snpp->debug(10);
$snpp->two_way();
$snpp->pager_id( $pager_number );
$snpp->data( $message );
$snpp->message_response( 1, "Acknowledge" );
$snpp->message_response( 2, "Decline" );
$snpp->message_response( 3, "Escalate" );
my @msg = $snpp->send_two_way();

$snpp->quit();

print "Check message status with these two numbers: '$msg[0] $msg[1]'\n";

exit 0;


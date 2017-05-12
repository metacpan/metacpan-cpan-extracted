#!/usr/local/ActivePerl-5.8/bin/perl -w
#
# $Id: sdee.pl,v 1.2 2005/03/04 20:34:16 jminieri Exp $
#
use strict;

use Net::SDEE;
#use XML::SDEE;
use Data::Dumper;

sub local_debug {
	my $message = shift;
	print "LOCAL_DEBUG: $message\n";
}

sub eventCallback {
	my ($event, $subscriptionId) = @_;
	
	print "##########\n";
	if(defined($subscriptionId)) {
		print "SubscriptionID: $subscriptionId\n";
	}

	print "EVENT Details:\n";
	foreach my $k ( keys %$event ) {
		print "KEY: $k\tVAL: $event->{ $k }\n";
	}

	print "##########\n";
	
}

sub xmlCallback {
	my ($event, $subscriptionId) = @_;
	
	print "##########\n";
	if(defined($subscriptionId)) {
		print "SubscriptionID: $subscriptionId\n";
	}

	print "EVENT Details:\n";
	print Dumper($event);

	print "##########\n";
	
}

my $s = Net::SDEE->new( 
	returnXML => 1,
	debug => 1,
	callback => \&xmlCallback,
	debug_callback => \&local_debug
);
#my $s = Net::SDEE->new( returnEvents => 1, callback => \&eventCallback, debug_callback => \&local_debug);
#my $s = Net::SDEE->new( returnEvents => 1, debug =>1);

$s->Username('username');
$s->Password('password');
$s->Server('server');

$s->open();

$s->getAll();
$s->closeAll();

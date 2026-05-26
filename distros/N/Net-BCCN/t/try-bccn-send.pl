#!/usr/bin/perl
use strict;
use lib '../lib';
use Net::BCCN;
use Data::Dumper;


#my @m = Net::BCCN::parse_notification_msg_data( "BCCN1[85]?:11:test|It is by the fortune of God that, in this country, we have three benefits:.[0A]" );
#print Dumper( \@m );
#die;



my $nt = new Net::BCCN PORT => 1122;

$nt->open() or die "cannot open sockets: " . $nt->err();

#print Dumper( $nt );

#sleep 2;
$nt->notify( 'ztest', `fortune` );
$nt->notify( 'ztest', `fortune` );
$nt->notify( 'ztest', `fortune` );
$nt->notify( 'ztest', `fortune` );
$nt->notify( 'test1', `fortune` );
$nt->notify( 'test1', `fortune` );
$nt->notify( 'test1', `fortune` );
$nt->notify( 'test1', `fortune` );
$nt->notify( 'test', `fortune` );
$nt->notify( 'test', `fortune` );
$nt->notify( 'test', 'WOW ' . `fortune` );


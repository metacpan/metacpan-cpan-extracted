#!/usr/bin/perl

use Netx::WebRadio;
use Netx::WebRadio::Station::Shoutcast::FileWriter;
use strict;

# define the stations here:
# host, port, [ optional stream-path, default / ]
my @server = (

# POP TOP40 Radiostorm.com
[ '64.236.34.141','80','/stream/1022'],

# DIGITALLY IMPORTED - European Trance, Techno, Hi-NRG...
[ '205.188.209.193','80','/stream/1003' ],
);

my $receiver = Netx::WebRadio->new();

my %serversBySocket;
foreach my $server (@server) {
	my $station = Netx::WebRadio::Station::Shoutcast::FileWriter->new();
	$station->host( $server->[0] );
	$station->port( $server->[1] );
	$station->path( $server->[2] );
	$station->useragent( 'Nullsoft Winamp3 version 3.0c build 488' );
	if ( $station->connect( $server->[0], $server->[1] ) ) {
	    $receiver->add_station( $station );
	    #print "connect successfull\n";
	} else {
	    print "connect NOT successfull\n";
	}
}

while ($receiver->number_of_stations) {
    $receiver->receive();
}

print "all connections closed\n";


#!/usr/local/bin/perl -wT

# This is a CGI script that interfaces to stem. it collects all the
# CGI data and sends it to a Stem::SockMsg cell as a single
# Stem::Packet.  It reads a single Stem::Packet back from the socket
# and uses the data in there to generate a response page.

$|++ ;

use strict ;
use lib '/wrk/stem/src/stem/lib/' ;

use CGI ;
use CGI::Carp qw(fatalsToBrowser) ;
use IO::Socket ;

use Stem::Packet ;

my $cgi = CGI->new() ;

my %cgi_data ;

# get all the cgi data we can

$cgi_data{ 'params' }	= get_cgi_data( 'param' ) ;
$cgi_data{ 'cookies' }	= get_cgi_data( 'cookie' ) ;
#$cgi_data{ 'env' }	= { %ENV } ;
#$cgi_data{ 'self_url' }	= $cgi->self_url() ;
$cgi_data{ 'url' }	= $cgi->url() ;
#$cgi_data{ 'cgi' }	= $cgi ;

# todo: handle default host:port here

my $data = send_and_get_packet( \%cgi_data ) ;

# use Data::Dumper ;

# print $cgi->header() ;
# # print "<PRE>\n", Dumper( \%cgi_data ), "\n</PRE>\n" ;
# print "<PRE>\n", Dumper( $data ), "\n</PRE>\n" ;

# exit ;

if ( ref $data eq 'SCALAR' ) {

	print $$data ;
	exit ;
}

print $cgi->header(), <<HTML ;
<HTML>
cgi2stem error: $data
</HTML>
HTML



# this works for both cookies and params as their APIs are the same

sub get_cgi_data {

	my( $type ) = @_ ;

	my %cgi_info ;

	foreach my $name ( $cgi->$type() ) { ;

		my @values = $cgi->$type( $name ) ;

		if ( @values > 1 ) {
			$cgi_info{ $type } = \@values ;
			next ;
		}

		$cgi_info{ $name } = shift @values ;
	}

	return \%cgi_info ;
}

sub send_and_get_packet {

	my( $in_data, $host, $port ) = @_ ;

	$port ||= 9999 ;
	$host ||= 'localhost' ;

	my $sock = IO::Socket::INET->new( "$host:$port" ) ;

	$sock or return "can't connect to $host:$port\n" ;

	my $packet = Stem::Packet->new( codec => 'Storable' ) ;

	my $write_buf = $packet->to_packet($in_data) ;

	syswrite( $sock, $$write_buf ) ;

	my $read_buf  ;

	while( 1 ) {

		my $bytes_read = sysread( $sock, $read_buf, 8192 ) ;

		return "sysread error $!" unless defined $bytes_read ;
		return "sysread closed" if $bytes_read == 0 ;

		my $result = $packet->to_data( $read_buf ) ;

		return $result if $result ;
	}
}

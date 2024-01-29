#!/usr/bin/perl
# $Id: 03-header.t 1953 2023-12-24 09:03:14Z willem $
#

use strict;
use warnings;
use Test::More tests => 75;
use TestToolkit;

use Net::DNS::Packet;
use Net::DNS::Parameters;


my $packet = Net::DNS::Packet->new(qw(. NS IN));
my $header = $packet->header;
ok( $header->isa('Net::DNS::Header'), 'packet->header object' );


sub toggle {
	my ( $object, $attribute, @sequence ) = @_;
	for my $value (@sequence) {
		my $change = $object->$attribute($value);
		my $stored = $object->$attribute();
		is( $stored, $value, "expected value after header->$attribute($value)" );
	}
	return;
}


my $newid = Net::DNS::Packet->new()->header->id(undef);
ok( $newid, 'expected non-zero packet ID' );

toggle( $header, 'opcode', qw(QUERY UPDATE DSO) );
toggle( $header, 'id',	   $header->id, 0, $header->id );	# Zero ID => DSO unidirectional
toggle( $header, 'opcode', qw(QUERY) );
toggle( $header, 'id',	   $header->id, $newid, $header->id );

toggle( $header, 'rcode', qw(REFUSED FORMERR NOERROR) );

toggle( $header, 'qr', 1, 0, 1, 0 );
toggle( $header, 'aa', 1, 0, 1, 0 );
toggle( $header, 'tc', 1, 0, 1, 0 );
toggle( $header, 'rd', 0, 1, 0, 1 );
toggle( $header, 'ra', 1, 0, 1, 0 );
toggle( $header, 'ad', 1, 0, 1, 0 );
toggle( $header, 'cd', 1, 0, 1, 0 );


#
#  Is $header->string remotely sane?
#
like( $header->string, '/opcode = QUERY/', 'string() has QUERY opcode' );
like( $header->string, '/qdcount = 1/',	   'string() has qdcount correct' );
like( $header->string, '/ancount = 0/',	   'string() has ancount correct' );
like( $header->string, '/nscount = 0/',	   'string() has nscount correct' );
like( $header->string, '/arcount = 0/',	   'string() has arcount correct' );

$header->opcode('UPDATE');
like( $header->string, '/opcode = UPDATE/', 'string() has UPDATE opcode' );
like( $header->string, '/zocount = 1/',	    'string() has zocount correct' );
like( $header->string, '/prcount = 0/',	    'string() has prcount correct' );
like( $header->string, '/upcount = 0/',	    'string() has upcount correct' );
like( $header->string, '/adcount = 0/',	    'string() has adcount correct' );

$header->opcode('DSO');
like( $header->string, '/opcode = DSO/', 'string() has DSO opcode' );


#
# Check that the aliases work
#
my $rr = Net::DNS::RR->new('example.com. 10800 A 192.0.2.1');
my @rr = ( $rr, $rr );
$packet->push( prereq	  => $rr );
$packet->push( update	  => $rr, @rr );
$packet->push( additional => @rr, @rr );

is( $header->zocount, $header->qdcount, 'zocount value matches qdcount' );
is( $header->prcount, $header->ancount, 'prcount value matches ancount' );
is( $header->upcount, $header->nscount, 'upcount value matches nscount' );
is( $header->adcount, $header->arcount, 'adcount value matches arcount' );


my $data = $packet->data;

my $packet2 = Net::DNS::Packet->new( \$data );

my $string = $packet->header->string;

is( $packet2->header->string, $string, 'encode/decode transparent' );


SKIP: {
	my $size = $header->size;
	my $edns = $header->edns;
	ok( $edns->isa('Net::DNS::RR::OPT'), 'header->edns object' );

	skip( 'EDNS header extensions not supported', 10 ) unless $edns->isa('Net::DNS::RR::OPT');

	toggle( $header, 'do', 0, 1, 0, 1 );
	toggle( $header, 'rcode', qw(BADVERS BADMODE BADNAME FORMERR NOERROR) );

	my $packet = Net::DNS::Packet->new();			# empty EDNS size solicitation
	my $udplim = 1280;
	$packet->edns->UDPsize($udplim);
	my $encoded = $packet->data;
	my $decoded = Net::DNS::Packet->new( \$encoded );
	is( $decoded->edns->UDPsize, $udplim, 'EDNS size request assembled correctly' );
}


eval {					## no critic		# exercise printing functions
	require IO::File;
	my $file   = "03-header.tmp";
	my $handle = IO::File->new( $file, '>' ) || die "Could not open $file for writing";
	select( ( select($handle), $header->print )[0] );
	close($handle);
	unlink($file);
};


exception( 'qdcount read-only', sub { $header->qdcount(0) } );
exception( 'ancount read-only', sub { $header->ancount(0) } );
exception( 'nscount read-only', sub { $header->nscount(0) } );
exception( 'adcount read-only', sub { $header->adcount(0) } );

noexception( 'warnings not repeated', sub { $header->qdcount(0) } );

exit;


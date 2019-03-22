# $Id: 03-header.t 1727 2018-12-31 12:04:48Z willem $

use strict;
use Test::More;

use Net::DNS::Packet;
use Net::DNS::Parameters;

plan tests => 72;


my $packet = new Net::DNS::Packet(qw(. NS IN));
my $header = $packet->header;
ok( $header->isa('Net::DNS::Header'), 'packet->header object' );


sub waggle {
	my $object    = shift;
	my $attribute = shift;
	my @sequence  = @_;
	for my $value (@sequence) {
		my $change = $object->$attribute($value);
		my $stored = $object->$attribute();
		is( $stored, $value, "expected value after header->$attribute($value)" );
	}
}


my $newid = new Net::DNS::Packet->header->id;
waggle( $header, 'id', $header->id, $newid, $header->id );

waggle( $header, 'opcode', qw(STATUS UPDATE QUERY) );
waggle( $header, 'rcode',  qw(REFUSED FORMERR NOERROR) );

waggle( $header, 'qr', 1, 0, 1, 0 );
waggle( $header, 'aa', 1, 0, 1, 0 );
waggle( $header, 'tc', 1, 0, 1, 0 );
waggle( $header, 'rd', 0, 1, 0, 1 );
waggle( $header, 'ra', 1, 0, 1, 0 );
waggle( $header, 'ad', 1, 0, 1, 0 );
waggle( $header, 'cd', 1, 0, 1, 0 );


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


#
# Check that the aliases work
#
my $rr = new Net::DNS::RR('example.com. 10800 A 192.0.2.1');
my @rr = ( $rr, $rr );
$packet->push( prereq	  => $rr );
$packet->push( update	  => $rr, @rr );
$packet->push( additional => @rr, @rr );

is( $header->zocount, $header->qdcount, 'zocount value matches qdcount' );
is( $header->prcount, $header->ancount, 'prcount value matches ancount' );
is( $header->upcount, $header->nscount, 'upcount value matches nscount' );
is( $header->adcount, $header->arcount, 'adcount value matches arcount' );


foreach my $method (qw(qdcount ancount nscount arcount)) {
	local $Net::DNS::Header::warned;
	eval {
		local $SIG{__WARN__} = sub { die @_ };
		$header->$method(1);
	};
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "$method read-only:\t[$exception]" );

	eval {
		local $SIG{__WARN__} = sub { die @_ };
		$header->$method(1);
	};
	my $repeated = $1 if $@ =~ /^(.+)\n/;
	ok( !$repeated, "$method exception not repeated" );
}


my $data = $packet->data;

my $packet2 = new Net::DNS::Packet( \$data );

my $string = $packet->header->string;

is( $packet2->header->string, $string, 'encode/decode transparent' );


SKIP: {
	my $size = $header->size;
	my $edns = $header->edns;
	ok( $edns->isa('Net::DNS::RR::OPT'), 'header->edns object' );

	skip( 'EDNS header extensions not supported', 10 ) unless $edns->isa('Net::DNS::RR::OPT');

	waggle( $header, 'do', 0, 1, 0, 1 );
	waggle( $header, 'rcode', qw(BADVERS BADMODE BADNAME FORMERR NOERROR) );

	my $packet = new Net::DNS::Packet();			# empty EDNS size solicitation
	my $udplim = 1280;
	$packet->edns->size($udplim);
	my $encoded = $packet->data;
	my $decoded = new Net::DNS::Packet( \$encoded );
	is( $decoded->edns->size, $udplim, 'EDNS size request assembled correctly' );
}


eval {					## exercise printing functions
	my $filename = "03-header.tmp";
	open( TEMP, ">$filename" ) || die "Could not open $filename for writing";
	select( ( select(TEMP), $header->print )[0] );
	close(TEMP);
	unlink($filename);
};


exit;


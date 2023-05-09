#!/usr/bin/perl
# $Id: 04-packet.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 102;
use TestToolkit;


use_ok('Net::DNS::Packet');


#	new() class constructor method must return object of appropriate class
my $object = Net::DNS::Packet->new();
ok( $object->isa('Net::DNS::Packet'), 'new() object' );

ok( $object->header,			      'header() method works' );
ok( $object->header->isa('Net::DNS::Header'), 'header() returns header object' );

ok( $object->edns,			     'edns() method works' );
ok( $object->edns->isa('Net::DNS::RR::OPT'), 'edns() returns OPT RR object' );

like( $object->string, '/HEADER/', 'string() returns representation of packet' );
$object->header->do(1);
$object->encode();
like( $object->string, '/EDNS/', 'string() contains representation of EDNS' );
$object->header->opcode('UPDATE');
like( $object->string, '/UPDATE/', 'string() returns representation of update' );


#	Empty packet created when new() arguments omitted
my $empty = Net::DNS::Packet->new();
ok( $empty, 'create empty packet' );
foreach my $method ( qw(question answer authority additional), qw(zone pre prerequisite update) ) {
	my @result = $empty->$method;
	ok( @result == 0, "$method() returns empty list" );
}


#	Create a DNS query packet
my ( $domain, $type, $class ) = qw(example.test MX IN);
my $question = Net::DNS::Question->new( $domain, $type, $class );

my $packet = Net::DNS::Packet->new( $domain, $type, $class );
like( $packet->string, "/$class\t$type/", 'create query packet' );

my @question = $packet->question;
ok( @question && @question == 1, 'packet->question() returns single element list' );
my ($q) = @question;
ok( $q->isa('Net::DNS::Question'), 'list element is a question object' );
is( $q->string, $question->string, 'question object correct' );


#	data() method returns non-empty scalar
my $packet_data = $packet->data;
ok( $packet_data, 'packet->data() method works' );


#	new(\$data) class constructor method returns object of appropriate class
my $packet2 = Net::DNS::Packet->new( \$packet_data );
ok( $packet2->isa('Net::DNS::Packet'), 'new(\$data) object' );
is( $packet2->string, $packet->string, 'decoded packet matches original' );

is( unpack( 'H*', $packet2->data ), unpack( 'H*', $packet_data ), 'retransmitted packet matches original' );

my $empty_packet = Net::DNS::Packet->new()->data;
ok( Net::DNS::Packet->new( \$empty_packet )->string, 'decoded empty packet' );

my $dso = Net::DNS::Packet->new();
$dso->header->opcode('DSO');
my $dso_packet = $dso->data . pack( 'n2H*', 1, 2, 'beef' );
ok( Net::DNS::Packet->new( \$dso_packet )->string, 'decoded DSO packet' );


#	Use push() to add RRs to each section
my $update = Net::DNS::Packet->new('.');
my $index;
foreach my $section (qw(answer authority additional)) {
	my $i	= ++$index;
	my $rr1 = Net::DNS::RR->new(
		Name	=> "$section$i.example.test",
		Type	=> "A",
		Address => "10.0.0.$i"
		);
	my $string1 = $rr1->string;
	my $count1  = $update->push( $section, $rr1 );
	like( $update->string, "/$string1/", "push first RR into $section section" );
	is( $count1, 1, "push() returns $section RR count" );

	my $j	= ++$index;
	my $rr2 = Net::DNS::RR->new(
		Name	=> "$section$j.example.test",
		Type	=> "A",
		Address => "10.0.0.$j"
		);
	my $string2 = $rr2->string;
	my $count2  = $update->push( $section, $rr2 );
	like( $update->string, "/$string2/", "push second RR into $section section" );
	is( $count2, 2, "push() returns $section RR count" );
}

# Add enough distinct labels to render compression unusable at some point
for ( 0 .. 255 ) {
	$update->push( 'answer', Net::DNS::RR->new( "X$_ TXT \"" . pack( "A255", "x" ) . '"' ) );
}
$update->push( 'answer', Net::DNS::RR->new('XY TXT ""') );
$update->push( 'answer', Net::DNS::RR->new('VW.XY TXT ""') );

#	Decode data buffer and compare with original
my $buffer  = $update->data;
my $decoded = eval { Net::DNS::Packet->new( \$buffer ) };
ok( $decoded, 'new() from data buffer works' );
is( $decoded->size, length($buffer), '$decoded->size() works' );
$decoded->from('local');
ok( $decoded->from(),	'$decoded->from() works' );
ok( $decoded->string(), '$decoded->string() works' );

foreach my $count (qw(qdcount ancount nscount arcount)) {
	is( $decoded->header->$count, $update->header->$count, "check header->$count correct" );
}
ok( $decoded->answersize, 'answersize() alias works' );
ok( $decoded->answerfrom, 'answerfrom() alias works' );


foreach my $section (qw(question)) {
	my @original = map { $_->string } $update->$section;
	my @content  = map { $_->string } $decoded->$section;
	is_deeply( \@content, \@original, "check content of $section section" );
}

foreach my $section (qw(answer authority additional)) {
	my @original = map { $_->ttl(0); $_->string } $update->$section;    # almost! need TTL defined
	my @content  = map { $_->string } $decoded->$section;
	is_deeply( \@content, \@original, "check content of $section section" );
}


#	check that pop() removes RR from section	Memo to self: no RR in question section!
foreach my $section (qw(answer authority additional)) {
	my $c1 = $update->push( $section, Net::DNS::RR->new('X TXT ""') );
	my $rr = $update->pop($section);
	my $c2 = $update->push($section);
	is( $c2, $c1 - 1, "pop() RR from $section section" );
}


for my $packet ( Net::DNS::Packet->new('example.com') ) {
	my $case1 = $packet->pop('');	## check tolerance of invalid pop
	my $case2 = $packet->pop('bogus');
}


#	Test using a predefined answer.
#	This is an answer that was generated by a bind server, with an option munged on the end.

my $BIND = pack( 'H*',
'22cc85000001000000010001056461636874036e657400001e0001c00c0006000100000e100025026e730472697065c012046f6c6166c02a7754e1ae0000a8c0000038400005460000001c2000002910000000800000050000000130'
	);

my $bind = Net::DNS::Packet->new( \$BIND );

is( $bind->header->qdcount, 1, 'check question count in synthetic packet header' );
is( $bind->header->ancount, 0, 'check answer count in synthetic packet header' );
is( $bind->header->nscount, 1, 'check authority count in synthetic packet header' );
is( $bind->header->adcount, 1, 'check additional count in synthetic packet header' );

for my $packet ( Net::DNS::Packet->new('example.com') ) {
	my $reply = $packet->reply();	## check $packet->reply()
	ok( $reply->isa('Net::DNS::Packet'), '$packet->reply() returns packet' );

	my $udpmax = 2048;
	$packet->edns->udpsize($udpmax);
	$packet->data;
	is( $packet->reply($udpmax)->edns->udpsize(), $udpmax, 'packet->reply() supports EDNS' );
}


for my $packet ( Net::DNS::Packet->new() ) {	## check $packet->sigrr
	my $sigrr = Net::DNS::RR->new( type => 'TSIG' );
	my $other = Net::DNS::RR->new( type => 'AAAA' );
	$packet->unique_push( 'additional' => $other );
	is( $packet->sigrr(),  undef, 'sigrr() undef for unsigned packet' );
	is( $packet->verify(), undef, 'verify() fails for unsigned packet' );
	ok( $packet->verifyerr(), 'verifyerr() returned for unsigned packet' );
	is( ref( $packet->sign_tsig($sigrr) ), ref($sigrr), 'sign_tsig() returns TSIG record' );
	is( $packet->verifyerr(),	       '',	    'verifyerr() returns empty string' );
	$packet->push( 'additional' => $sigrr );
	is( ref( $packet->sigrr() ), ref($sigrr), 'sigrr() returns TSIG record' );
}


eval {					## no critic		# exercise dump and debug diagnostics
	require IO::File;
	require Data::Dumper;
	local $Data::Dumper::Maxdepth;
	local $Data::Dumper::Sortkeys;
	local $Data::Dumper::Useqq;
	my $packet  = Net::DNS::Packet->new();
	my $buffer  = $packet->data;
	my $corrupt = substr $buffer, 0, 10;
	my $file    = '04-packet.txt';
	my $handle  = IO::File->new( $file, '>' ) || die "Could not open $file for writing";
	select( ( select($handle), $packet->dump )[0] );
	$Data::Dumper::Maxdepth = 6;
	$Data::Dumper::Sortkeys = 1;
	$Data::Dumper::Useqq	= 1;
	select( ( select($handle), $packet->dump )[0] );
	select( ( select($handle), Net::DNS::Packet->new( \$buffer,  1 )->dump )[0] );
	select( ( select($handle), Net::DNS::Packet->new( \$corrupt, 1 ) )[0] );
	close($handle);
	unlink($file);
};


for my $packet ( Net::DNS::Packet->new(qw(example.com. A IN)) ) {
	my $wire = $packet->data;
	while ( length($wire) ) {
		chop($wire);
		my $n = length($wire);	## Note: need to re-raise exception trapped by constructor
		exception( "decode truncated ($n octets)", sub { Net::DNS::Packet->decode( \$wire ); die } );
	}

	my $sig = Net::DNS::RR->new( type => 'SIG' );
	exception( 'reply->reply()', sub { $packet->reply->reply } );
	exception( 'sign_tsig(...)', sub { $packet->sign_tsig($packet) } );
	exception( 'sign_sig0(...)', sub { $packet->sign_sig0($packet) } );
	exception( 'sig0 verify()',  sub { $packet->sign_sig0($sig); $packet->verify } );
}

exit;


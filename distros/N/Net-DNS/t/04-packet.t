# $Id: 04-packet.t 1449 2016-02-01 12:27:12Z willem $	-*-perl-*-

use strict;

BEGIN {
	use Test::More tests => 99;

	use_ok('Net::DNS');
}


#	new() class constructor method must return object of appropriate class
my $object = Net::DNS::Packet->new();
ok( $object->isa('Net::DNS::Packet'), 'new() object' );

ok( $object->header,			      'header() method works' );
ok( $object->header->isa('Net::DNS::Header'), 'header() returns header object' );

ok( $object->edns,			     'edns() method works' );
ok( $object->edns->isa('Net::DNS::RR::OPT'), 'edns() returns OPT RR object' );

like( $object->string, '/HEADER/', 'string() returns representation of packet' );
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


#	new(\$data) class constructor captures exception text when data truncated
my @data = unpack 'C*', $packet->data;
while (@data) {
	pop(@data);
	my $truncated = pack 'C*', @data;
	my $length    = length $truncated;
	my $object    = Net::DNS::Packet->new( \$truncated );
	my $exception = $@;
	$exception =~ s/\n.*$//g;
	ok( $exception, "truncated ($length octets):\t[$exception]" );
}


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
	my $count1 = $update->push( $section, $rr1 );
	like( $update->string, "/$string1/", "push first RR into $section section" );
	is( $count1, 1, "push() returns $section RR count" );

	my $j	= ++$index;
	my $rr2 = Net::DNS::RR->new(
		Name	=> "$section$j.example.test",
		Type	=> "A",
		Address => "10.0.0.$j"
		);
	my $string2 = $rr2->string;
	my $count2 = $update->push( $section, $rr2 );
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
my $buffer = $update->data;
my $decoded = eval { Net::DNS::Packet->new( \$buffer ) };
ok( $decoded, 'new() from data buffer works' );
is( $decoded->answersize, length($buffer), '$decoded->answersize() works' );
$decoded->answerfrom('local');
ok( $decoded->answerfrom(), '$decoded->answerfrom() works' );
ok( $decoded->string(),	    '$decoded->string() works' );
foreach my $count (qw(qdcount ancount nscount arcount)) {
	is( $decoded->header->$count, $update->header->$count, "check header->$count correct" );
}


foreach my $section (qw(question)) {
	my @original = map { $_->string } $update->$section;
	my @content  = map { $_->string } $decoded->$section;
	is_deeply( \@content, \@original, "check content of $section section" );
}

foreach my $section (qw(answer authority additional)) {
	my @original = map { $_->ttl(0); $_->string } $update->$section;    # almost! need TTL defined
	my @content = map { $_->string } $decoded->$section;
	is_deeply( \@content, \@original, "check content of $section section" );
}


#	check that pop() removes RR from section	Memo to self: no RR in question section!
foreach my $section (qw(answer authority additional)) {
	my $c1 = $update->push( $section, Net::DNS::RR->new('X TXT ""') );
	my $rr = $update->pop($section);
	my $c2 = $update->push($section);
	is( $c2, $c1 - 1, "pop() RR from $section section" );
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

my ($rr) = $bind->additional;

is( $rr->type, 'OPT',  'Additional section packet is EDNS0 type' );
is( $rr->size, '4096', 'EDNS0 packet size correct' );


{					## check tolerance of invalid pop
	my $packet = new Net::DNS::Packet('example.com');
	my $case1  = $packet->pop('');
	my $case2  = $packet->pop('bogus');
}


{					## check $packet->reply()
	my $packet = new Net::DNS::Packet('example.com');
	my $reply  = $packet->reply();
	ok( $reply->isa('Net::DNS::Packet'), '$packet->reply() returns packet' );
	eval { $reply->reply(); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "reply->reply()\t[$exception]" );
	my $udpmax = 2048;
	$packet->edns->size($udpmax);
	$packet->data;
	is( $packet->reply($udpmax)->edns->size(), $udpmax, 'packet->reply() supports EDNS' );
}


{					## check $packet->sigrr
	my $packet = new Net::DNS::Packet();
	is( $packet->sigrr(), undef, 'sigrr() undef for empty packet' );
	$packet->push( additional => new Net::DNS::RR( type => 'OPT' ) );
	is( $packet->sigrr(),  undef, 'sigrr() undef for unsigned packet' );
	is( $packet->verify(), undef, 'verify() fails for unsigned packet' );
	ok( $packet->verifyerr(), 'verifyerr() returned for unsigned packet' );
}


{					## go through the motions of SIG0
	my $packet = new Net::DNS::Packet('example.com');
	my $sig = new Net::DNS::RR( type => 'SIG' );
	ok( $packet->sign_sig0($sig), 'sign_sig0() returns SIG0 record' );
	is( ref( $packet->sigrr() ), ref($sig), 'sigrr() returns SIG RR' );

	eval { $packet->sign_sig0( [] ); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "sign_sig0([])\t[$exception]" );
}


{					## check exception raised for bad TSIG
	my $packet = new Net::DNS::Packet('example.com');
	my $bogus = new Net::DNS::RR( type => 'NULL' );
	eval { $packet->sign_tsig($bogus); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "sign_tsig([])\t[$exception]" );
}


eval {					## exercise but do not test print
	require Data::Dumper;
	local $Data::Dumper::Maxdepth;
	local $Data::Dumper::Sortkeys;
	my $object   = new Net::DNS::Packet('example.com');
	my $buffer   = $object->data;
	my $corrupt  = substr $buffer, 0, 10;
	my $filename = '04-packet.txt';
	open( TEMP, ">$filename" ) || die "Could not open $filename for writing";
	select( ( select(TEMP), $object->print )[0] );
	select( ( select(TEMP), $object->dump )[0] );
	$Data::Dumper::Maxdepth = 6;
	$Data::Dumper::Sortkeys = 1;
	select( ( select(TEMP), $object->dump )[0] );
	select( ( select(TEMP), Net::DNS::Packet->new( \$buffer, 1 ) )[0] );
	select( ( select(TEMP), Net::DNS::Packet->new( \$corrupt, 1 ) )[0] );
	close(TEMP);
	unlink($filename);
};


exit;


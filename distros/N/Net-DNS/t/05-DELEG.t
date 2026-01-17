#!/usr/bin/perl
# $Id: 05-DELEG.t 2043 2026-01-14 13:35:59Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Net::DNS;

use Test::More;
use TestToolkit;

exit( plan skip_all => 'unresolved AUTOLOAD regression	[perl #120694]' )
		unless ( $] > 5.018001 )
		or ( $] < 5.018 );

plan tests => 47;


my $type = 'DELEG';

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
ok( $typecode, "$type RR type code = $typecode" );


for my $rr ( Net::DNS::RR->new( my $record = "example. $type" ) ) {
	ok( $rr, "parse RR:	$record" );
	is( $rr->rdata,		 '',	'empty rdata' );
	is( $rr->mandatory,	 undef, 'mandatory undefined' );
	is( $rr->server_ipv4,	 undef, 'server_ipv4 undefined' );
	is( $rr->server_ipv6,	 undef, 'server_ipv6 undefined' );
	is( $rr->server_name,	 undef, 'server_name undefined' );
	is( $rr->include_delegi, undef, 'include_delegi undefined' );
	ok( $rr->string,  'presentation format string' );
	ok( $rr->generic, 'RFC3597 generic format' );
}


for my $rr ( Net::DNS::RR->new( my $record = "example. $type server-ipv4=192.0.2.1,192.0.2.2" ) ) {
	ok( $rr,		 "parse RR:	$record" );
	ok( defined $rr->key1(), 'correct parameter key defined' );
	my @list = eval { $rr->server_ipv4 };
	is( scalar(@list), 2, '$rr->server_ipv4 returns address list' );
}

for my $rr ( Net::DNS::RR->new( my $record = "example. $type server-ipv6=2001:db8::1,2001:db8::2" ) ) {
	ok( $rr,		 "parse RR:	$record" );
	ok( defined $rr->key2(), 'correct parameter key defined' );
	my @list = eval { $rr->server_ipv6 };
	is( scalar(@list), 2, '$rr->server_ipv6 returns address list' );
}

for my $rr ( Net::DNS::RR->new( my $record = "example. $type server-name=nameserver.example" ) ) {
	ok( $rr,		 "parse RR:	$record" );
	ok( defined $rr->key3(), 'correct parameter key defined' );
	is( $rr->server_name, 'nameserver.example.', '$rr->server_name returns domain name' );
}

for my $rr ( Net::DNS::RR->new( my $record = qq(example. $type include-delegi="devolved.example") ) ) {
	ok( $rr,		 "parse RR:	$record" );
	ok( defined $rr->key4(), 'correct parameter key defined' );
	is( $rr->include_delegi, 'devolved.example.', '$rr->include_delegi returns domain name' );
}


for my $rr ( Net::DNS::RR->new( my $record = "example. 0 IN $type" ) ) {
	ok( $rr, "parse RR:	$record" );
	is( $rr->rdata, '', 'empty rdata' );
	ok( $rr->mandatory( 1, 2, 3 ),		      'mandatory write access method' );
	ok( $rr->server_ipv4('192.0.2.1'),	      'server_ipv4 write access method' );
	ok( $rr->server_ipv6('2001:db8::53'),	      'server_ipv6 write access method' );
	ok( $rr->server_name('nameserver.example.'),  'server_name write access method' );
	ok( $rr->include_delegi('devolved.example.'), 'include_delegi write access method' );
	ok( $rr->rdata,				      'non-empty rdata' );
	ok( $rr->encode,			      'wire-format octet string' );
	ok( !$rr->key65500(undef),		      'delete parameter' );
	ok( $rr->_parameter( 65500, '!' ),	      'unexpected parameter' );
	ok( $rr->string,			      'presentation format string' );
	ok( $rr->generic,			      'RFC3597 generic format' );
	my $encoded = $rr->encode;
	my $decoded = ref($rr)->decode( \$encoded );
	is( $decoded->generic, $rr->generic, 'encode/decode transparent' );
	my $rdata = pack 'n2a*', 65500, 5, 'xxxx';
	local $rr->{rdlength} = length $rdata;
	exception( 'rdata corruption', sub { $rr->_decode_rdata( \$rdata, 0 ) } );
}


exception( 'duplicated parameter',   sub { Net::DNS::RR->new("example. $type include-delegi=x include-delegi=y") } );
exception( 'incompatible parameter', sub { Net::DNS::RR->new("example. $type include-delegi=x server-name=y") } );
exception( 'invalid argument',	     sub { Net::DNS::RR->new("example. $type include-delegi=.") } );
exception( 'invalid argument',	     sub { Net::DNS::RR->new("example. $type server-name=.") } );
exception( 'unexpected argument',    sub { Net::DNS::RR->new("example. $type")->key65500(qw(X Y)) } );
exception( 'unrecognised parameter', sub { Net::DNS::RR->new("example. $type bogus") } );
exception( 'mandatory key0 in list', sub { Net::DNS::RR->new("example. $type mandatory=server-ipv4,key0") } );
exception( 'mandatory key repeated', sub { Net::DNS::RR->new("example. $type mandatory=key1,key1") } );
exception( 'mandatory key required', sub { Net::DNS::RR->new("example. $type mandatory=key2,key3 key2=X") } );
exception( 'mandatory key unknown',  sub { Net::DNS::RR->new("example. $type mandatory=bogus") } );

exit;


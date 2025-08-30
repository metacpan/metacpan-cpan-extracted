#!/usr/bin/perl
# $Id: 05-DELEG.t 2039 2025-08-26 09:01:09Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Net::DNS;

use Test::More;
use TestToolkit;

exit( plan skip_all => 'unresolved AUTOLOAD regression	[perl #120694]' )
		unless ( $] > 5.018001 )
		or ( $] < 5.018 );

plan tests => 48;


my $type = 'DELEG';

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
ok( $typecode, "$type RR type code = $typecode" );


for my $rr ( Net::DNS::RR->new( my $record = 'example. DELEG' ) ) {
	ok( $rr, "new DELEG RR:	$record" );
	is( $rr->server_ip4,   undef, 'server_ip4 undefined' );
	is( $rr->server_ip6,   undef, 'server_ip6 undefined' );
	is( $rr->server_name,  undef, 'server_name undefined' );
	is( $rr->include_name, undef, 'include_name undefined' );
	is( $rr->rdata,	       '',    'empty rdata' );
	ok( $rr->string,  'presentation format string' );
	ok( $rr->generic, 'RFC3597 generic format' );
}


for my $rr ( Net::DNS::RR->new( my $record = 'example. DELEG server-ip4=192.0.2.1,192.0.2.2' ) ) {
	ok( $rr,		 "new DELEG RR:	$record" );
	ok( defined $rr->key1(), 'correct parameter key defined' );
	my @list = eval { $rr->server_ip4 };
	ok( scalar @list, '$rr->server_ip4 returns address list' );
	is( $rr->include_name, undef, 'include_name undefined' );
}

for my $rr ( Net::DNS::RR->new( my $record = 'example. DELEG server-ip6=2001:db8::1' ) ) {
	ok( $rr,		 "new DELEG RR:	$record" );
	ok( defined $rr->key2(), 'correct parameter key defined' );
	my @list = eval { $rr->server_ip6 };
	ok( scalar @list, '$rr->server_ip6 returns address list' );
	is( $rr->include_name, undef, 'include_name undefined' );
}

for my $rr ( Net::DNS::RR->new( my $record = 'example. DELEG server-name=nameserver.example' ) ) {
	ok( $rr,		 "new DELEG RR:	$record" );
	ok( defined $rr->key3(), 'correct parameter key defined' );
	is( $rr->server_name,  'nameserver.example.', '$rr->server_name returns domain name' );
	is( $rr->include_name, undef,		      'include_name undefined' );
}

for my $rr ( Net::DNS::RR->new( my $record = 'example. DELEG include-name="devolved.example"' ) ) {
	ok( $rr,		 "new DELEG RR:	$record" );
	ok( defined $rr->key4(), 'correct parameter key defined' );
	is( $rr->include_name, 'devolved.example.', '$rr->include_name returns domain name' );
	is( $rr->server_name,  undef,		    'server_name undefined' );
	is( $rr->server_ip4,   undef,		    'server_ip4 undefined' );
	is( $rr->server_ip6,   undef,		    'server_ip6 undefined' );
}


for my $rr ( Net::DNS::RR->new( my $record = 'example. 0 IN DELEG' ) ) {
	ok( $rr, "new DELEG RR:	$record" );
	is( $rr->rdata, '', 'empty rdata' );
	ok( $rr->server_ip4('192.0.2.1'),	     'server_ip4 write access method' );
	ok( $rr->server_ip6('2001:db8::53'),	     'server_ip6 write access method' );
	ok( $rr->server_name('nameserver.example.'), 'server_name write access method' );
	ok( $rr->include_name('devolved.example.'),  'include_name write access method' );
	ok( $rr->rdata,				     'non-empty rdata' );
	ok( $rr->encode,			     'wire-format octet string' );
	ok( !$rr->_parameter( 4, undef ),	     'delete include_name parameter' );
	ok( $rr->_parameter( 65500, '!' ),	     'unexpected parameter' );
	ok( $rr->string,			     'presentation format string' );
	ok( $rr->generic,			     'RFC3597 generic format' );
	my $encoded = $rr->encode;
	my $decoded = ref($rr)->decode( \$encoded );
	is( $decoded->generic, $rr->generic, 'encode/decode transparent' );
	my $rdata = pack 'n2a*', 65500, 5, 'xxxx';
	local $rr->{rdlength} = length $rdata;
	exception( 'rdata corruption', sub { $rr->_decode_rdata( \$rdata, 0 ) } );
}


exception( 'duplicated parameter',   sub { Net::DNS::RR->new('example. DELEG include-name=x include-name=y') } );
exception( 'incompatible parameter', sub { Net::DNS::RR->new('example. DELEG include-name=x server-name=y') } );
exception( 'invalid argument',	     sub { Net::DNS::RR->new('example. DELEG include-name=.') } );
exception( 'invalid argument',	     sub { Net::DNS::RR->new('example. DELEG server-name=.') } );
exception( 'unexpected arguments',   sub { Net::DNS::RR->new('example. DELEG server-name=x,y') } );
exception( 'unsupported parameter',  sub { Net::DNS::RR->new('example. DELEG')->key65500('') } );
exception( 'unrecognised parameter', sub { Net::DNS::RR->new('example. DELEG bogus') } );

exit;


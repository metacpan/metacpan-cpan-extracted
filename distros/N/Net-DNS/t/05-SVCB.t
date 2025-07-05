#!/usr/bin/perl
# $Id: 05-SVCB.t 2017 2025-06-27 13:48:03Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Net::DNS;
use Net::DNS::ZoneFile;

use Test::More;
use TestToolkit;

exit( plan skip_all => 'unresolved AUTOLOAD regression	[perl #120694]' )
		unless ( $] > 5.018001 )
		or ( $] < 5.018 );

plan tests => 49;


my $name = 'SVCB.example';
my $type = 'SVCB';
my $code = 64;
my @attr = qw( svcpriority targetname port );
my @data = qw( 1 pool.svc.example 1234 );
my @also = qw(mandatory alpn no-default-alpn port ipv4hint ech ipv6hint dohpath ohttp);

my $wire = '000104706f6f6c03737663076578616d706c65000003000204d2';

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
is( $typecode, $code, "$type RR type code = $code" );

my $hash = {};
@{$hash}{@attr} = @data;


for my $rr ( Net::DNS::RR->new( name => $name, type => $type, %$hash ) ) {
	my $string = $rr->string;
	my $rr2	   = Net::DNS::RR->new($string);
	is( $rr2->string, $string, 'new/string transparent' );

	is( $rr2->encode, $rr->encode, 'new($string) and new(%hash) equivalent' );

	foreach (qw(svcpriority targetname)) {
		is( $rr->$_, $hash->{$_}, "expected result from rr->$_()" );
	}

	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my $hex1    = unpack 'H*', $encoded;
	my $hex2    = unpack 'H*', $decoded->encode;
	my $hex3    = unpack 'H*', $rr->rdata;
	is( $hex2, $hex1, 'encode/decode transparent' );
	is( $hex3, $wire, 'encoded RDATA matches example' );
}


for my $rr ( Net::DNS::RR->new(". $type") ) {
	foreach ( qw(TargetName), @also ) {
		is( $rr->$_(), undef, "empty RR has undefined $_" );
	}

	$rr->SvcPriority(1);
	$rr->TargetName('.');
	my $l0 = length $rr->encode;
	$rr->no_default_alpn(0);
	$rr->no_default_alpn(1);
	isnt( length( $rr->encode ), $l0, 'insert SvcParams key' );
	$rr->no_default_alpn(undef);
	is( length( $rr->encode ), $l0, 'delete SvcParams key' );

	exception( 'non-existent method', sub { $rr->bogus } );
}


for my $corruption ( pack 'H*', '00004000010000000000070001000bad0001' ) {
	local $SIG{__WARN__} = sub { };
	my $rr = Net::DNS::RR->decode( \$corruption );
	like( $rr->string, '/corrupt/i', 'string() includes corrupt RDATA' );
}


Net::DNS::RR->new(<<'END')->print;
example.com.	SVCB	16 foo.example.org.	( mandatory=alpn alpn=h2,h3-19
			no-default-alpn port=1234 ipv4hint=192.0.2.1
			ech=AEP+DQA/BAAgACCW2/dfOBZAtQU55/py/BlhdRdaauPAkrERAUwppoeSEgAEAAEAAQAQY2QxLnRlc3QuZGVmby5pZQAA
			ipv6hint=2001:db8::1
			dohpath=/dns-query{?dns}
			ohttp
			tls-supported-groups=29,23
			)
END


####	Test Vectors

my $zonefile = Net::DNS::ZoneFile->new( \*DATA );

sub testcase {
	my $ident  = shift;
	my $vector = $zonefile->read;
	my $expect = $zonefile->read;
	is( $vector->string, $expect->string, $ident );
	return;
}

sub failure {
	my $ident = shift;
	exception( "$ident", sub { $zonefile->read } );
	return;
}


testcase('SVCB Alias Form');

testcase('SVCB Service Form');
testcase('SVCB defines a port');
testcase('unregistered key, unquoted value');
testcase('unregistered key, quoted with decimal escape');
testcase('two IPv6 hints in quoted presentation format');
testcase('single IPv6 hint in IPv4 mapped IPv6 format');
testcase('unsorted SvcParams and mandatory key list');

failure('alpn with escaped escape and escaped comma');		# Appendix A not implemented
$zonefile->read();
failure('alpn with numeric escape and escaped comma');
$zonefile->read();

failure('key already defined');

foreach my $key (qw(mandatory alpn port ipv4hint ech ipv6hint)) {
	failure("no argument ($key)");
}
failure('no-default-alpn + value');
failure('port + multiple values');
failure('ech  + multiple values');

failure('mandatory lists key0');
failure('duplicate mandatory key');
failure('undefined mandatory key');
failure('alpn not specified');

failure('unrecognised key name');
failure('invalid SvcParam key');
failure('non-numeric port value');
failure('corrupt wire format');

exit;


__DATA__

;;	D.1.	Alias Form

example.com.	SVCB	0 foo.example.com.
example.com	SVCB	\# 19 (
00 00							; priority
03 66 6f 6f 07 65 78 61 6d 70 6c 65 03 63 6f 6d 00	; target
)


;;	D.2.	Service Form

example.com.	SVCB	1 .
example.com	SVCB	\# 3 (
00 01							; priority
00							; target (root label)
)


example.com.	SVCB	16 foo.example.com. port=53
example.com	SVCB	\# 25 (
00 10							; priority
03 66 6f 6f 07 65 78 61 6d 70 6c 65 03 63 6f 6d 00	; target
00 03							; key 3
00 02							; length 2
00 35							; value
)


example.com.	SVCB	1 foo.example.com. key667=hello
example.com	SVCB	\# 28 (
00 01							; priority
03 66 6f 6f 07 65 78 61 6d 70 6c 65 03 63 6f 6d 00	; target
02 9b							; key 667
00 05							; length 5
68 65 6c 6c 6f						; value
)


example.com.   SVCB   1 foo.example.com. key667="hello\210qoo"
example.com	SVCB	\# 32 (
00 01							; priority
03 66 6f 6f 07 65 78 61 6d 70 6c 65 03 63 6f 6d 00	; target
02 9b							; key 667
00 09							; length 9
68 65 6c 6c 6f d2 71 6f 6f				; value
)


example.com.   SVCB   1 foo.example.com. ipv6hint="2001:db8::1,2001:db8::53:1"
example.com	SVCB	\# 55 (
00 01							; priority
03 66 6f 6f 07 65 78 61 6d 70 6c 65 03 63 6f 6d 00	; target
00 06							; key 6
00 20							; length 32
20 01 0d b8 00 00 00 00 00 00 00 00 00 00 00 01		; first address
20 01 0d b8 00 00 00 00 00 00 00 00 00 53 00 01		; second address
)


example.com.   SVCB   1 example.com. ipv6hint="::ffff:198.51.100.100"
example.com	SVCB	\# 35 (
00 01							; priority
07 65 78 61 6d 70 6c 65 03 63 6f 6d 00			; target
00 06							; key 6
00 10							; length 16
00 00 00 00 00 00 00 00 00 00 ff ff c6 33 64 64		; address
)


example.com.	SVCB	1 foo.example.org. (		; unsorted SvcParam keys
			key23609 key23600 mandatory=key23609,key23600
			)
example.com	SVCB	\# 35 (
00 01							; priority
03 66 6f 6f 07 65 78 61 6d 70 6c 65 03 6f 72 67 00	; target
00 00							; key 0
00 04							; param length 4
5c 30							; value: key 23600
5c 39							; value: key 23609
5c 30							; key 23600
00 00							; param length 0
5c 39							; key 23609
00 00							; param length 0
)


foo.example.com	SVCB	16 foo.example.org. alpn="f\\\\oo\\,bar,h2"
foo.example.com	SVCB	\# 35 (
00 10							; priority
03 66 6f 6f 07 65 78 61 6d 70 6c 65 03 6f 72 67 00	; target
00 01							; key 1
00 0c							; param length 12
08							; alpn length 8
66 5c 6f 6f 2c 62 61 72					; alpn value
02							; alpn length 2
68 32							; alpn value
)

foo.example.com	SVCB	16 foo.example.org. alpn=f\\\092oo\092,bar,h2
foo.example.com	SVCB	\# 35 (
00 10							; priority
03 66 6f 6f 07 65 78 61 6d 70 6c 65 03 6f 72 67 00	; target
00 01							; key 1
00 0c							; param length 12
08							; alpn length 8
66 5c 6f 6f 2c 62 61 72					; alpn value
02							; alpn length 2
68 32							; alpn value
)


;;	D.3.	Failure Cases

example.com.	SVCB	1 foo.example.com. (
			key123=abc key123=def
			)

example.com.	SVCB	1 foo.example.com. mandatory
example.com.	SVCB	1 foo.example.com. alpn
example.com.	SVCB	1 foo.example.com. port
example.com.	SVCB	1 foo.example.com. ipv4hint
example.com.	SVCB	1 foo.example.com. ech
example.com.	SVCB	1 foo.example.com. ipv6hint

example.com.	SVCB	1 foo.example.com. no-default-alpn=abc
example.com.	SVCB	1 foo.example.com. port=1234,5678
example.com.	SVCB	1 foo.example.com. ech=b25l,Li4u

example.com.	SVCB	1 foo.example.com. mandatory=mandatory
example.com.	SVCB	1 foo.example.com. (
			mandatory=key123,key123 key123=abc
			)
example.com.	SVCB	1 foo.example.com. mandatory=key123

example.com.	SVCB	1 foo.example.com. (
			no-default-alpn		; without expected alpn
			)


example.com.	SVCB	1 foo.example.com. mandatory=bogus
example.com.	SVCB	1 foo.example.com. key65535=invalid
example.com.	SVCB	1 foo.example.com. port=1234X5

example.com.	SVCB	( \# 25 0001		; 1
	03666f6f076578616d706c6503636f6d 00	; foo.example.com.
	0003 0003 0035 )			; corrupt wire format


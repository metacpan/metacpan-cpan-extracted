#!/usr/bin/perl
# $Id: 05-DELEG.t 2033 2025-07-29 18:03:07Z willem $	-*-perl-*-
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

plan tests => 28;


my $type = 'DELEG';
my $code = $Net::DNS::Parameters::typebyname{$type};

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
is( $typecode, $code, "$type RR type code = $code" );


for my $rr ( Net::DNS::RR->new( my $record = 'example. IN DELEG' ) ) {
	ok( $rr, "new DELEG RR:	$record" );
	is( $rr->priority,   undef, 'undefined priority' );
	is( $rr->targetname, undef, 'undefined targetname' );
	ok( $rr->string,  'presentation format string' );
	ok( $rr->generic, 'RFC3597 generic format' );
}


for my $rr ( Net::DNS::RR->new( my $record = 'example. DELEG DIRECT=servername' ) ) {
	ok( $rr, "new DELEG RR:	$record" );
	isnt( $rr->priority, 0, 'non-zero priority' );
	ok( $rr->targetname, 'defined targetname' );
	ok( $rr->string,     'presentation format string' );
	ok( $rr->generic,    'RFC3597 generic format' );
}


for my $rr ( Net::DNS::RR->new( my $record = 'example. DELEG DIRECT=servername IPv4=192.0.2.1 port=53 key65534' ) ) {
	ok( $rr, "new DELEG RR:	$record" );
	is( $rr->priority, 1, 'default priority 1' );
	ok( $rr->priority(123), 'set arbitrary priority' );
	is( $rr->priority, 123, 'verify changed priority' );
	exception( 'zero priority value rejected', sub { $rr->priority(0) } );
	ok( $rr->string, 'presentation format string' );
}


for my $rr (
	Net::DNS::RR->new(
		my $record = 'example. DELEG IPv6=2001:db8::53 alpn=dot key2 tls-supported-groups=29'
		)
	) {
	ok( $rr, "new DELEG RR:	$record" );
	is( $rr->targetname, undef, 'undefined targetname' );
	ok( $rr->string, 'presentation format string' );
}


for my $rr ( Net::DNS::RR->new( my $record = 'example. DELEG INCLUDE="targetname"' ) ) {
	ok( $rr, "new DELEG RR:	$record" );
	is( $rr->priority, 0, 'zero priority' );
	ok( $rr->targetname, 'defined targetname' );
	ok( $rr->string,     'presentation format string' );
	is( $rr->priority(0), 0, 'zero priority silently accepted' );
	exception( 'non-zero priority rejected', sub { $rr->priority(1) } );
}

exception( 'incomplete INCLUDE parameter',    sub { Net::DNS::RR->new('example. DELEG INCLUDE') } );
exception( 'incomplete DIRECT parameter set', sub { Net::DNS::RR->new('example. DELEG DIRECT') } );

exit;


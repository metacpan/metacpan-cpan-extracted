#!/usr/bin/perl
# $Id: 02-mailbox.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 40;
use TestToolkit;


use_ok('Net::DNS::Mailbox');


for my $mailbox ( Net::DNS::Mailbox->new('mbox@example.com') ) {
	ok( $mailbox->isa('Net::DNS::Mailbox'), 'object returned by new() constructor' );
	$mailbox->address;		## untestable optimisation: avoid returning address in void context
	ok( $mailbox->address, 'mailbox->address' );
}


my %testcase = (
	'.'				    => '<>',
	'<>'				    => '<>',
	'a'				    => 'a',
	'a.b'				    => 'a@b',
	'a.b.c'				    => 'a@b.c',
	'a.b.c.d'			    => 'a@b.c.d',
	'a@b'				    => 'a@b',
	'a@b.c'				    => 'a@b.c',
	'a@b.c.d'			    => 'a@b.c.d',
	'a\.b.c.d'			    => 'a.b@c.d',
	'a\.b@c.d'			    => 'a.b@c.d',
	'empty <>'			    => '<>',
	'fore <a.b@c.d> aft'		    => 'a.b@c.d',
	'nested <<mailbox>>'		    => 'mailbox',
	'obscure <<left><<<deep>>><right>>' => 'right',
	'obsolete <@source;@route:mailbox>' => 'mailbox',
	'quoted <"stuff@local"@domain>'	    => '"stuff@local"@domain',
	);

foreach my $test ( sort keys %testcase ) {
	my $expect  = $testcase{$test};
	my $mailbox = Net::DNS::Mailbox->new($test);
	my $data    = $mailbox->encode;
	my $decoded = Net::DNS::Mailbox->decode( \$data );
	is( $decoded->address, $expect, "encode/decode mailbox	$test" );
}


for my $mailbox ( Net::DNS::Mailbox->new( uc 'MBOX.EXAMPLE.COM' ) ) {
	my $hash      = {};
	my $data      = $mailbox->encode( 1,		$hash );
	my $compress  = $mailbox->encode( length $data, $hash );
	my $canonical = $mailbox->encode( length $data );
	my $decoded   = Net::DNS::Mailbox->decode( \$data );
	my $downcased = Net::DNS::Mailbox->new( lc $mailbox->name )->encode( 0, {} );
	ok( $mailbox->isa('Net::DNS::Mailbox'), 'object returned by Net::DNS::Mailbox->new()' );
	ok( $decoded->isa('Net::DNS::Mailbox'), 'object returned by Net::DNS::Mailbox->decode()' );
	is( length $compress, length $data, 'Net::DNS::Mailbox encoding is uncompressed' );
	isnt( $data, $downcased, 'Net::DNS::Mailbox encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::Mailbox canonical form is uncompressed' );
	isnt( $canonical, $downcased, 'Net::DNS::Mailbox canonical form preserves case' );
}


for my $mailbox ( Net::DNS::Mailbox1035->new( uc 'MBOX.EXAMPLE.COM' ) ) {
	my $hash      = {};
	my $data      = $mailbox->encode( 1,		$hash );
	my $compress  = $mailbox->encode( length $data, $hash );
	my $canonical = $mailbox->encode( length $data );
	my $decoded   = Net::DNS::Mailbox1035->decode( \$data );
	my $downcased = Net::DNS::Mailbox1035->new( lc $mailbox->name )->encode( 0, {} );
	ok( $mailbox->isa('Net::DNS::Mailbox1035'), 'object returned by Net::DNS::Mailbox1035->new()' );
	ok( $decoded->isa('Net::DNS::Mailbox1035'), 'object returned by Net::DNS::Mailbox1035->decode()' );
	isnt( length $compress, length $data, 'Net::DNS::Mailbox1035 encoding is compressible' );
	isnt( $data,		$downcased,   'Net::DNS::Mailbox1035 encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::Mailbox1035 canonical form is uncompressed' );
	is( $canonical,	       $downcased,   'Net::DNS::Mailbox1035 canonical form is lower case' );
}


for my $mailbox ( Net::DNS::Mailbox2535->new( uc 'MBOX.EXAMPLE.COM' ) ) {
	my $hash      = {};
	my $data      = $mailbox->encode( 1,		$hash );
	my $compress  = $mailbox->encode( length $data, $hash );
	my $canonical = $mailbox->encode( length $data );
	my $decoded   = Net::DNS::Mailbox2535->decode( \$data );
	my $downcased = Net::DNS::Mailbox2535->new( lc $mailbox->name )->encode( 0, {} );
	ok( $mailbox->isa('Net::DNS::Mailbox2535'), 'object returned by Net::DNS::Mailbox2535->new()' );
	ok( $decoded->isa('Net::DNS::Mailbox2535'), 'object returned by Net::DNS::Mailbox2535->decode()' );
	is( length $compress, length $data, 'Net::DNS::Mailbox2535 encoding is uncompressed' );
	isnt( $data, $downcased, 'Net::DNS::Mailbox2535 encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::Mailbox2535 canonical form is uncompressed' );
	is( $canonical,	       $downcased,   'Net::DNS::Mailbox2535 canonical form is lower case' );
}


exception( 'empty argument list', sub { Net::DNS::Mailbox->new() } );
exception( 'argument undefined',  sub { Net::DNS::Mailbox->new(undef) } );

exit;


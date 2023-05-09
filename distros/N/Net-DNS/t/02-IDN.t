#!/usr/bin/perl
# $Id: 02-IDN.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;
use TestToolkit;

## vvv	verbatim from Domain.pm
use constant ASCII => ref eval {
	require Encode;
	Encode::find_encoding('ascii');
};

use constant UTF8 => scalar eval {	## not UTF-EBCDIC  [see UTR#16 3.6]
	Encode::encode_utf8( chr(182) ) eq pack( 'H*', 'C2B6' );
};

use constant LIBIDN2 => defined eval { require Net::LibIDN2 };
use constant LIBIDN  => LIBIDN2 ? undef : defined eval { require Net::LibIDN };
## ^^^	verbatim from Domain.pm


use constant LIBIDNOK => LIBIDN && scalar eval {
	my $cn = pack( 'U*', 20013, 22269 );
	Net::LibIDN::idn_to_ascii( $cn, 'utf-8' ) eq 'xn--fiqs8s';
};

use constant LIBIDN2OK => LIBIDN2 && scalar eval {
	my $cn = pack( 'U*', 20013, 22269 );
	Net::LibIDN2::idn2_to_ascii_8( $cn, 9 ) eq 'xn--fiqs8s';
};


my $codeword = unpack 'H*', '[|';
my %codename = (
	'5b7c' => 'ASCII superset',
	'ba4f' => 'EBCDIC cp37',
	'ad4f' => 'EBCDIC cp1047',
	'bb4f' => 'EBCDIC posix-bc'
	);
my $encoding = $codename{lc $codeword} || "not recognised	[$codeword]";
diag "character encoding: $encoding" unless $encoding =~ /ASCII/;


plan skip_all => 'Encode package not installed' unless eval { require Encode; };

plan skip_all => 'Encode: ASCII encoding not available' unless ASCII;

plan skip_all => 'Encode: UTF-8 encoding not available' unless UTF8;

plan skip_all => 'Net::LibIDN2 not installed' unless LIBIDN || LIBIDN2;

plan skip_all => 'Net::LibIDN not working' if LIBIDN && !LIBIDNOK;

plan skip_all => 'Net::LibIDN2 not working' if LIBIDN2 && !LIBIDN2OK;

plan tests => 12;


use_ok('Net::DNS::Domain');


my $a_label = 'xn--fiqs8s';
my $u_label = eval { pack( 'U*', 20013, 22269 ); };

is( Net::DNS::Domain->new($a_label)->name,   $a_label,	  'IDN A-label domain->name' );
is( Net::DNS::Domain->new($a_label)->fqdn,   "$a_label.", 'IDN A-label domain->fqdn' );
is( Net::DNS::Domain->new($a_label)->string, "$a_label.", 'IDN A-label domain->string' );
is( Net::DNS::Domain->new($a_label)->xname,  $u_label,	  'IDN A-label domain->xname' );

is( Net::DNS::Domain->new($u_label)->name,   $a_label,	  'IDN U-label domain->name' );
is( Net::DNS::Domain->new($u_label)->fqdn,   "$a_label.", 'IDN U-label domain->fqdn' );
is( Net::DNS::Domain->new($u_label)->string, "$a_label.", 'IDN U-label domain->string' );
is( Net::DNS::Domain->new($u_label)->xname,  $u_label,	  'IDN U-label domain->xname' );


is( Net::DNS::Domain->new($u_label)->xname, $u_label, 'IDN cached domain->xname' );

is( Net::DNS::Domain->new('xn--')->xname, 'xn--', 'IDN bogus domain->xname' );


exception( 'new(invalid name)', sub { Net::DNS::Domain->new( pack 'U*', 65533, 92, 48, 65533 ) } );

exit;


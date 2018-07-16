# $Id: 02-IDN.t 1692 2018-07-06 08:55:39Z willem $	-*-perl-*-

use strict;
use Test::More;

					## vvv	verbatim from Domain.pm
use constant ASCII => ref eval {
	require Encode;
	Encode::find_encoding('ascii');
};

use constant UTF8 => scalar eval {	## not UTF-EBCDIC  [see UTR#16 3.6]
	Encode::encode_utf8( chr(182) ) eq pack( 'H*', 'C2B6' );
};

use constant LIBIDN  => defined eval 'require Net::LibIDN';
use constant LIBIDN2 => ref eval 'require Net::LibIDN2; Net::LibIDN2->can("idn2_to_ascii_8")';
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

is( new Net::DNS::Domain($a_label)->name,   $a_label,	 'IDN A-label domain->name' );
is( new Net::DNS::Domain($a_label)->fqdn,   "$a_label.", 'IDN A-label domain->fqdn' );
is( new Net::DNS::Domain($a_label)->string, "$a_label.", 'IDN A-label domain->string' );
is( new Net::DNS::Domain($a_label)->xname,  $u_label,	 'IDN A-label domain->xname' );

is( new Net::DNS::Domain($u_label)->name,   $a_label,	 'IDN U-label domain->name' );
is( new Net::DNS::Domain($u_label)->fqdn,   "$a_label.", 'IDN U-label domain->fqdn' );
is( new Net::DNS::Domain($u_label)->string, "$a_label.", 'IDN U-label domain->string' );
is( new Net::DNS::Domain($u_label)->xname,  $u_label,	 'IDN U-label domain->xname' );


is( new Net::DNS::Domain($u_label)->xname, $u_label, 'IDN cached domain->xname' );

is( new Net::DNS::Domain('xn--')->xname, 'xn--', 'IDN bogus domain->xname' );


eval { new Net::DNS::Domain( pack 'U*', 65533, 92, 48, 65533 ); };
my $exception = $1 if $@ =~ /^(.+)\n/;
ok( $exception ||= '', "invalid name\t[$exception]" );


exit;


#!/usr/bin/perl
# $Id: 03-parameters.t 1921 2023-05-08 18:39:59Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;
use TestToolkit;

use Net::DNS::Parameters qw(:class :type :opcode :rcode :ednsoption :dsotype);

plan tests => ( 5 + scalar keys %Net::DNS::Parameters::classbyval ) +
		( 4 + scalar keys %Net::DNS::Parameters::typebyval ) +
		( 5 + scalar keys %Net::DNS::Parameters::opcodebyval ) +
		( 3 + scalar keys %Net::DNS::Parameters::rcodebyval ) +
		( 2 + scalar keys %Net::DNS::Parameters::ednsoptionbyval ) +
		( 2 + scalar keys %Net::DNS::Parameters::dsotypebyval );


foreach ( sort { $a <=> $b } 32767, keys %Net::DNS::Parameters::classbyval ) {
	my $name = classbyval($_);	## check class conversion functions
	my $code = eval { classbyname($name) };
	is( $code, $_, "classbyname($name)" );
}


foreach ( sort { $a <=> $b } 65535, keys %Net::DNS::Parameters::typebyval ) {
	my $name = typebyval($_);	## check type conversion functions
	my $code = eval { typebyname($name) };
	is( $code, $_, "typebyname($name)" );
}
is( typebyname('*'), typebyname('ANY'), "typebyname(*)" );


foreach ( sort { $a <=> $b } 255, keys %Net::DNS::Parameters::opcodebyval ) {
	my $name = opcodebyval($_);	## check OPCODE type conversion functions
	my $code = eval { opcodebyname($name) };
	is( $code, $_, "opcodebyname($name)" );
}
is( opcodebyname('NS_NOTIFY_OP'), opcodebyname('NOTIFY'), "opcodebyname(NS_NOTIFY_OP)" );


foreach ( sort { $a <=> $b } 4095, keys %Net::DNS::Parameters::rcodebyval ) {
	my $name = rcodebyval($_);	## check RCODE conversion functions
	my $code = eval { rcodebyname($name) };
	is( $code, $_, "rcodebyname($name)" );
}
is( rcodebyname('BADVERS'), rcodebyname('BADSIG'), "rcodebyname(BADVERS)" );


foreach ( sort { $a <=> $b } 65535, keys %Net::DNS::Parameters::ednsoptionbyval ) {
	my $name = ednsoptionbyval($_);	## check EDNS option conversion functions
	my $code = eval { ednsoptionbyname($name) };
	is( $code, $_, "ednsoptionbyname($name)" );
}


foreach ( sort { $a <=> $b } 65535, keys %Net::DNS::Parameters::dsotypebyval ) {
	my $name = dsotypebyval($_);	## check DSO type conversion functions
	my $code = eval { dsotypebyname($name) };
	is( $code, $_, "dsotypebyname($name)" );
}


exception( 'classbyval',  sub { classbyval(65536) } );
exception( 'classbyname', sub { classbyname(65536) } );
exception( 'classbyname', sub { classbyname('CLASS65536') } );
exception( 'classbyname', sub { classbyname('BOGUS') } );

exception( 'typebyval',	 sub { typebyval(65536) } );
exception( 'typebyname', sub { typebyname(65536) } );
exception( 'typebyname', sub { typebyname('CLASS65536') } );
exception( 'typebyname', sub { typebyname('BOGUS') } );

exception( 'opcodebyname', sub { opcodebyname('BOGUS') } );

exception( 'rcodebyname', sub { rcodebyname('BOGUS') } );

exception( 'ednsoptionbyname', sub { ednsoptionbyname('BOGUS') } );

exception( 'dsotypebyname', sub { dsotypebyname('BOGUS') } );


exit;


#!/usr/bin/perl

# Compile-testing for PITA-Scheme

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;

BEGIN {
	ok( $] >= 5.005, 'Perl version is 5.005 or newer' );
	use_ok( 'PITA::Scheme'                  );
	use_ok( 'PITA::Scheme::Perl5'           );
	use_ok( 'PITA::Scheme::Perl5::Make'     );
	use_ok( 'PITA::Scheme::Perl5::Build'    );
	use_ok( 'PITA::Scheme::Perl'            );
	use_ok( 'PITA::Scheme::Perl::Discovery' );
}

is( $PITA::Scheme::VERSION, $PITA::Scheme::Perl::VERSION,            '::Scheme == ::Perl'      );
is( $PITA::Scheme::VERSION, $PITA::Scheme::Perl::Discovery::VERSION, '::Scheme == ::Discovery' );
is( $PITA::Scheme::VERSION, $PITA::Scheme::Perl5::VERSION,           '::Scheme == ::Perl5'     );
is( $PITA::Scheme::VERSION, $PITA::Scheme::Perl5::Make::VERSION,     '::Scheme == ::Make'      );
is( $PITA::Scheme::VERSION, $PITA::Scheme::Perl5::Build::VERSION,    '::Scheme == ::Build'     );

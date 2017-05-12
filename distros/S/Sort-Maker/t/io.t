#!/usr/local/bin/perl -sw

use strict ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

my @sort_styles = qw( plain orcish ST GRT ) ;

my $sort_tests = [

	{
		skip	=> 0,
		name	=> 'simple string',
		data	=> [ qw( z e a k ) ],
		gold	=> sub { $a cmp $b },
		sizes	=> [ 100, 1000 ],
#		sizes	=> [ 5000 ],
		gen	=> sub { rand_token() },
		args	=> {
			default	=> [ qw( string ) ],
			ref_in	=> [ qw( ref_in string ) ],
			ref_out	=> [ qw( ref_out string ) ],
			ref_in_ref_out	=> [ qw( ref_in ref_out string ) ],
		},
	},
	{
		skip	=> 0,
		name	=> 'simple number',
		data	=> [ 32, 2, 9, 7 ],
		gold	=> sub { $a <=> $b },
		sizes	=> [ 100, 1000 ],
		gen	=> sub { rand_number( 10 ) },
		args	=> {
			default	=> [ qw( number ) ],
			ref_in	=> [ qw( ref_in number ) ],
			ref_out	=> [ qw( ref_out number ) ],
			ref_in_ref_out	=> [ qw( ref_in ref_out number ) ],
		},
	},
] ;

our $bench ;

if ( $bench ) {
	benchmark_driver( $sort_tests, \@sort_styles ) ;
}
else {
	test_driver( $sort_tests, \@sort_styles ) ;
}

exit ;

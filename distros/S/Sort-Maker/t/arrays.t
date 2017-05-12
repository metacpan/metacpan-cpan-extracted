#!/usr/local/bin/perl -sw

use strict ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

my $sort_styles = [ qw( plain orcish ST GRT ) ] ;

my $sort_tests = [

	{
		skip	=> 0,
		name	=> 'arrays of strings',
		data	=> [ map {
				[ rand_token( 8, 20 ) ]
			} 1 .. 100
		],
		gold	=> sub { $a->[0] cmp $b->[0] },
		args	=> [ qw( string $_->[0] ) ],
	},
	{
		skip	=> 0,
		name	=> 'arrays of numbers',
		data	=> [ map {
				[ rand_number( 1, 20 ) ]
			} 1 .. 100
		],
		gold	=> sub { $a->[0] <=> $b->[0] },
		args	=> [ qw( number $_->[0] ) ],
	},
	{
		skip	=> 0,
		name	=> 'arrays of multiple strings',
		source	=> 0,
		data	=> [ map {
				[ rand_token( 8, 20 ), rand_token( 8, 20 ), ]
			} 1 .. 100
		],
		gold	=> sub { $a->[0] cmp $b->[0] ||
				 $a->[1] cmp $b->[1] },
		args	=> [ qw( string $_->[0] string $_->[1] ) ],
	},
	{
		skip	=> 0,
		name	=> 'arrays of multiple numbers',
		data	=> [ map {
				[ rand_number( 1, 20 ), rand_number( 1, 20 ) ]
			} 1 .. 100
		],
		gold	=> sub { $a->[0] <=> $b->[0] ||
				 $a->[1] <=> $b->[1] },
		args	=> [ qw( number $_->[0] number $_->[1] ) ],
	},
] ;

common_driver( $sort_tests, $sort_styles ) ;

exit ;

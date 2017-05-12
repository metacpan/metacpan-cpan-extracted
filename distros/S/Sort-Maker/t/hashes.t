#!/usr/local/bin/perl -sw

use strict ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

my @sort_styles = qw( plain orcish ST GRT ) ;

my $sort_tests = [

	{
		skip	=> 0,
		name	=> 'hashes of strings',
		data	=> [ map {
				{ a => rand_token( 8, 20 ) }
			} 1 .. 100
		],
		gold	=> sub { $a->{a} cmp $b->{a} },
		args	=> [ qw( string $_->{a} ) ],
	},
	{
		skip	=> 0,
		name	=> 'hashes of numbers',
		data	=> [ map {
				{ a => rand_number( 1, 20 ) }
			} 1 .. 100
		],
		gold	=> sub { $a->{a} <=> $b->{a} },
		args	=> [ qw( number $_->{a} ) ],
	},
	{
		skip	=> 0,
		name	=> 'hashes of multiple strings',
		data	=> [ map {
				{ a => rand_token( 8, 20 ),
				  b => rand_token( 8, 20 ), }
			} 1 .. 100
		],
		gold	=> sub { $a->{a} cmp $b->{a} ||
				 $a->{b} cmp $b->{b} },
		args	=> [ qw( string $_->{a} string $_->{b} ) ],
	},
	{
		skip	=> 0,
		name	=> 'hashes of multiple numbers',
		data	=> [ map {
				{ a => rand_number( 1, 20 ),
				  b => rand_number( 1, 20 ) }
			} 1 .. 100
		],
		gold	=> sub { $a->{a} <=> $b->{a} ||
				 $a->{b} <=> $b->{b} },
		args	=> [ qw( number $_->{a} number $_->{b} ) ],
	},
] ;

common_driver( $sort_tests, \@sort_styles ) ;

exit ;

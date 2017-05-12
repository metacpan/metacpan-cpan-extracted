#!/usr/local/bin/perl -sw

use strict ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

use vars qw( $a $b ) ;

my @sort_styles = qw( GRT ) ;

my $sort_tests = [

	{
		skip	=> 0,
#		source => 1,
		name	=> 'ref_in varying - max length',
		data	=> [ map {
				{ a => rand_token( 20, 30 ),
				  b => rand_token( 20, 30 ), }
			} 1 .. 5
		],
		gold	=> sub { $a->{a} cmp $b->{a} ||
				 $a->{b} cmp $b->{b} },
		args	=> {
			ref_in => [
			     qw( string $_->{a} string $_->{b} ref_in varying )
		 	],
		},
	},
	{
		skip	=> 0,
		name	=> 'ref_in varying descending - max length',
		data	=> [ map {
				{ a => rand_token( 20, 30 ),
				  b => rand_token( 20, 30 ), }
			} 1 .. 5
		],
		gold	=> sub { $b->{a} cmp $a->{a} ||
				 $b->{b} cmp $a->{b} },
		args	=> {
			ref_in => [
			     qw( string $_->{a} string $_->{b} ref_in
		varying descending )
		 	],
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

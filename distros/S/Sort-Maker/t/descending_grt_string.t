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
		name	=> 'descending fixed - numeric data',
		data	=> [ 'dog', 10, 'camel', 2 ],
		gold	=> sub { $b cmp $a },
		args	=> {

			fixed	=> [ qw( string descending fixed 3 ) ],
			varying	=> [ qw( string descending varying ) ],
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

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
		args	=> [ qw( string ) ],
	},
	{
		skip	=> 0,
		name	=> 'simple number',
		data	=> [ 32, 2, 9, 7 ],
		gold	=> sub { $a <=> $b },
		args	=> [ qw( number ) ],
	},
] ;

common_driver( $sort_tests, \@sort_styles ) ;

exit ;

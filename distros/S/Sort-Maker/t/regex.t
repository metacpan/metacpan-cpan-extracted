#!/usr/local/bin/perl -sw

use strict ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

my @sort_styles = qw( plain orcish ST GRT ) ;

my $sort_tests = [

	{
		skip	=> 0,
		name	=> 'regex string',
		gen	=> sub { rand_token() },
		gold	=> sub { ($a =~ /(\w+)/)[0] cmp ($b =~ /(\w+)/)[0] },
		args	=> [ qw( string /(\w+)/ ) ],
	},
	{
		skip	=> 0,
		source	=> 0,
		name	=> 'qr string',
		gen	=> sub { rand_token() },
		gold	=> sub { ($a =~ /(\w+)/)[0] cmp ($b =~ /(\w+)/)[0] },
		args	=> [ string => qr/(\w+)/ ],
	},
] ;

common_driver( $sort_tests, \@sort_styles ) ;

exit ;

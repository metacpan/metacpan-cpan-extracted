#!/usr/local/bin/perl -sw

use strict ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

use vars '$bench' ;

my @sort_styles = qw( GRT ) ;

my @string_keys = map rand_alpha( 4, 8 ), 1 .. 100 ;
my @number_keys = map int( rand_number( 100, 10000 ) ), 1 .. 100 ;

#print "STR @string_keys NUM @number_keys\n" ;

my $sort_tests = [
	{
		skip	=> 0,
		name	=> 'simple string',
		sizes	=> [100, 1000],
		gen	=> sub { rand_choice( @string_keys ) },
		gold	=> sub { $a cmp $b },
		args	=> {
			string => [ qw( string_data string ) ],
			index => [ qw( string ) ],
		}
	},
	{
		skip	=> 0,
		name	=> 'simple string no-case',
		sizes	=> [100, 1000],
		gen	=> sub { rand_choice( @string_keys ) },
		gold	=> sub { uc($a) cmp uc($b) },
		args	=> {
			string => [ qw( string_data string no_case ) ],
			index => [ qw( string no_case ) ],
		}
	},
	{
		skip	=> 0,
		source	=> 0,
		name	=> 'simple string descending',
		sizes	=> [100, 1000],
		gen	=> sub { rand_choice( @string_keys ) },
		gold	=> sub { $b cmp $a },
		args	=> {
			string => [ qw( string_data string
					descending varying ) ],
			index => [ qw( string descending varying ) ],
		}
	},
	{
		skip	=> 0,
		name	=> 'simple string no-case descending',
		sizes	=> [100, 1000],
		gen	=> sub { rand_choice( @string_keys ) },
		gold	=> sub { uc($b) cmp uc($a) },
		args	=> {
			string => [ qw( string_data string no_case
					descending varying ) ],
			index => [ qw( string no_case descending varying ) ],
		}
	},
	{
		skip	=> 0,
		name	=> 'simple number',
		sizes	=> [100, 1000],
		gen	=> sub { rand_choice( @number_keys ) },
		gold	=> sub { $a <=> $b },
		args	=> {
			string => [ qw( string_data number ) ],
			index => [ qw( number ) ],
		}
	},
	{
		skip	=> 0,
		source	=> 0,
		sizes	=> [100, 1000],
		name	=> 'string:number',
		gen	=> sub { rand_choice( @string_keys ) . ':' .
				 rand_choice( @number_keys )
		},
		gold	=> sub {
			 ($a =~ /^(\w+)/)[0] cmp ($b =~ /^(\w+)/)[0] 
				||
			 ($a =~ /(\d+)$/)[0] <=> ($b =~ /(\d+)$/)[0] 
		},
		args	=> {
			index	=> [ string => '/^(\w+)/',
				     number => '/(\d+)$/'
			],
			string	=> [ 'string_data',
				     string => '/^(\w+)/',
				     number => '/(\d+)$/'
			],
		},
	},
] ;

common_driver( $sort_tests, \@sort_styles ) ;

exit ;

#!/usr/local/bin/perl -sw

use strict ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

my @sort_styles = qw( ST GRT ) ;

my @string_keys = map rand_alpha( 4, 8 ), 1 .. 10 ;
my @number_keys = map int rand_number( 100, 10000 ), 1 .. 10 ;

my $sort_tests = [

	{
		skip	=> 0,
		source	=> 0,
		name	=> 'init_code',
		sizes	=> [400, 1000],
		gen	=> sub { rand_choice( @string_keys ) . ':' .
				 rand_choice( @number_keys ) },
		gold	=> sub {
			 ($a =~ /^(\w+)/)[0] cmp ($b =~ /^(\w+)/)[0]
			 		||
			 ($a =~ /(\d+$)/)[0] <=> ($b =~ /(\d+$)/)[0] 
		},
		args	=> {
			init_code => [
				init_code => 'my( $str, $num ) ;',
				string =>
				  'do{( $str, $num ) = /^(\w+):(\d+)$/; $str}',
				number => '$num',
			],
			no_init => [
				string => '/^(\w+)/',
				number => '/(\d+)$/'
			],
		},
	},
	{
		skip	=> 0,
		source	=> 0,
		name	=> 'deep init_code',
		sizes	=> [400, 1000],
		gen	=> sub { [[{'a' => rand_choice( @string_keys ) . ':' .
				 rand_choice( @number_keys )}]] },
		gold	=> sub {
			 ($a->[0][0]{a} =~ /^(\w+)/)[0] cmp
			 ($b->[0][0]{a} =~ /^(\w+)/)[0]
			 		||
			 ($a->[0][0]{a} =~ /(\d+$)/)[0] <=>
			 ($b->[0][0]{a} =~ /(\d+$)/)[0] 
		},
		args	=> {
			init_code => [
				init_code => 'my( $str, $num ) ;',
				string => 'do{( $str, $num ) =
					$_->[0][0]{a} =~ /^(\w+):(\d+)$/; $str}',
				number => '$num',
			],
			no_init => [
				string => '$_->[0][0]{a} =~ /^(\w+)/',
				number => '$_->[0][0]{a} =~ /(\d+$)/',
			],
		},
	},
] ;

common_driver( $sort_tests, \@sort_styles ) ;

exit ;

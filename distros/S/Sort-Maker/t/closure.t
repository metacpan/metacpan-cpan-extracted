#!/usr/local/bin/perl -s

use strict ;
use warnings ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

use vars '$bench' ;

#my @sort_styles = qw( plain ) ;
my @sort_styles = qw( plain orcish ST GRT ) ;

# These are some months to be sorted numerically.
my @months = qw( 
	January
	February
	March
	April
	May
	June
	July
	August
	September
	October
	November
	December
) ;

# a jumbled array of months to be sorted

my @month_jumble = qw(February June October March January
	April July November August December May September);

my %month_to_num ;
@month_to_num{ @months } = 1 .. @months ;

# These are some months to be sorted alphabetically
# (order determined by letters).

my %month_to_let ;
@month_to_let{ @months } = 'A' .. 'L' ;

my $sort_tests = [

	{
		skip	=> 0,
		name	=> 'closure error',
		gold	=> sub { $month_to_num{$a} <=> $month_to_num{$b} },
		error	=> qr/Global symbol "%month_to_num"/,
		args	=> {
			number => [
				number => sub { $month_to_num{$_} },
			],
		},
	},

	{
		skip	=> 0,
		source	=> 0,
		name	=> 'closure numeric',
		data	=> \@month_jumble,
		gold => sub { $month_to_num{$a} <=> $month_to_num{$b} },
		args	=> {
			number => [
				'closure',
				number => sub { $month_to_num{$_} },
			],
		},
	},

	{
		skip	=> 0,
		source	=> 0,
		name	=> 'closure string',
		data	=> \@month_jumble,
		gold => sub { $month_to_let{$a} cmp $month_to_let{$b} },
		args	=> {
			string => [
				'closure',
				string => sub { $month_to_let{$_} },
			],
		},
	},

	{
		skip	=> 0,
		name	=> 'double closure',
		data	=> [
			[ qw( November March ) ],
			[ qw( January March ) ],
			[ qw( July June ) ],
			[ qw( January January ) ],
		],
		gold	=> sub {
			$month_to_let{$a->[0]} cmp $month_to_let{$b->[0]}
				||
			$month_to_num{$a->[1]} <=> $month_to_num{$b->[1]}
		},
		args	=> {
			double => [
				'closure',
				string	=> sub { $month_to_let{$_->[0]} },
				number	=> sub { $month_to_num{$_->[1]} },
			 ],
		},
	},
] ;

common_driver( $sort_tests, \@sort_styles ) ;

exit ;

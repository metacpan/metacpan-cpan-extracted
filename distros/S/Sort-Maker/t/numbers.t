#!/usr/local/bin/perl -sw

use strict ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

my @sort_styles = qw( plain orcish ST GRT ) ;

my $sort_tests = [

	{
		skip	=> 0,
		name	=> 'unsigned float',
		gold	=> sub { $a <=> $b },
		gen	=> sub {
			rand_number( 0, 99999 ) *
			10 ** rand_number( -10, 3 )
		},
		args	=> [ qw( number unsigned_float ) ],
	},
	{
		skip	=> 0,
		name	=> 'signed float',
		gold	=> sub { $a <=> $b },
		gen	=> sub {
			rand_number( -99999, 99999 ) *
			10 ** rand_number( -10, 3 )
		},
		args	=> [ qw( number signed_float ) ],
	},
	{
		skip	=> 0,
		name	=> 'unsigned integer',
		gold	=> sub { $a <=> $b },
		gen	=> sub { int rand_number( 0, 99999999 ) },
		args	=> [ qw( number unsigned ) ],
	},
	{
		skip	=> 0,
		name	=> 'signed integer',
		gold	=> sub { $a <=> $b },
		gen	=> sub { int rand_number( -99999, 99999 ) },
		args	=> [ qw( number signed ) ],
	},
	{
		skip	=> 0,
		name	=> 'unsigned float edge case',
		gold	=> sub { $a <=> $b },
		data	=> [ reverse 0 .. 100 ],
		args	=> [ qw( number unsigned_float ) ],
	},
	{
		skip	=> 0,
		name	=> 'signed float edge case',
		gold	=> sub { $a <=> $b },
		data	=> [ reverse -100 .. 100 ],
		args	=> [ qw( number signed_float ) ],
	},
	{
		skip	=> 0,
		name	=> 'unsigned integer edge case',
		gold	=> sub { $a <=> $b },
		data	=> [ reverse 0 .. 100 ],
		args	=> [ qw( number unsigned ) ],
	},
	{
		skip	=> 0,
		name	=> 'signed integer edge case',
		gold	=> sub { $a <=> $b },
		data	=> [ -99999, 0, -999 .. 999, 99999 ],
		args	=> [ qw( number signed ) ],
	},
	{
		skip	=> 0,
		name	=> 'unsigned float descending',
		gold	=> sub { $b <=> $a },
		gen	=> sub {
			rand_number( 0, 99999 ) *
			10 ** rand_number( -10, 3 )
		},
		args	=> [ qw( number unsigned_float descending ) ],
	},
	{
		skip	=> 0,
		name	=> 'signed float descending',
		gold	=> sub { $b <=> $a },
		gen	=> sub {
			rand_number( -99999, 99999 ) *
			10 ** rand_number( -10, 3 )
		},
		args	=> [ qw( number signed_float descending ) ],
	},
	{
		skip	=> 0,
		name	=> 'unsigned integer descending',
		gold	=> sub { $b <=> $a },
		gen	=> sub { int rand_number( 0, 99999999 ) },
		args	=> [ qw( number unsigned descending) ],
	},
	{
		skip	=> 0,
		name	=> 'signed integer descending',
		gold	=> sub { $b <=> $a },
		gen	=> sub { int rand_number( -99999, 99999 ) },
		args	=> [ qw( number signed descending ) ],
	},
	{
		skip	=> 0,
		name	=> 'unsigned float edge case descending',
		gold	=> sub { $b <=> $a },
		data	=> [ reverse 0 .. 100 ],
		args	=> [ qw( number unsigned_float descending ) ],
	},
	{
		skip	=> 0,
		name	=> 'signed float edge case descending',
		gold	=> sub { $b <=> $a },
		data	=> [ reverse -100 .. 100 ],
		args	=> [ qw( number signed_float descending ) ],
	},
	{
		skip	=> 0,
		name	=> 'unsigned integer edge case descending',
		gold	=> sub { $b <=> $a },
		data	=> [ reverse 0 .. 100 ],
		args	=> [ qw( number unsigned descending ) ],
	},
	{
		skip	=> 0,
		name	=> 'signed integer edge case descending',
		gold	=> sub { $b <=> $a },
		data	=> [ -99999, 0, -999 .. 999, 99999 ],
		args	=> [ qw( number signed descending ) ],
	},

] ;

common_driver( $sort_tests, \@sort_styles ) ;

exit ;

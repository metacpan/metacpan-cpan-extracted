#!/usr/local/bin/perl -sw

use strict ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

my @sort_styles = qw( GRT ) ;

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
		name	=> 'unsigned integer',
		data	=> [ 32, 2, 9, 7 ],
		gold	=> sub { $a <=> $b },
		args	=> [ qw( unsigned number ) ],
	},
	{
		skip	=> 0,
		name	=> 'unsigned integer descending',
		data	=> [ 32, 2, 9, 7 ],
		gold	=> sub { $b <=> $a },
		args	=> [ qw( unsigned number descending ) ],
	},
	{
		skip	=> 0,
		name	=> 'signed integer',
		data	=> [ 32, -2, 9, -7 ],
		gold	=> sub { $a <=> $b },
		args	=> [ qw( signed number ) ],
	},
	{
		skip	=> 0,
		name	=> 'signed integer descending',
		data	=> [ 32, -2, 9, -7 ],
		gold	=> sub { $b <=> $a },
		args	=> [ qw( signed number descending ) ],
	},
	{
		skip	=> 0,
		name	=> 'unsigned float',
		data	=> [ 32, 2, 9, 7 ],
		gold	=> sub { $a <=> $b },
		args	=> [ qw( unsigned_float number ) ],
	},
	{
		skip	=> 0,
		name	=> 'unsigned float descending',
		data	=> [ 32, 2, 9, 7.0, 7.1 ],
		gold	=> sub { $b <=> $a },
		args	=> [ qw( unsigned_float number descending ) ],
	},
	{
		skip	=> 0,
		name	=> 'signed float',
		data	=> [ 32, -2, 9, -7 ],
		gold	=> sub { $a <=> $b },
		args	=> [ qw( signed_float number ) ],
	},
	{
		skip	=> 0,
		name	=> 'signed float descending',
		data	=> [ 32, -2, 9, -7.0, -7.1 ],
		gold	=> sub { $b <=> $a },
		args	=> [ qw( signed_float number descending ) ],
	},
	{
		skip	=> 0,
		name	=> 'plain string',
		data	=> [ qw( bdhd BDhd wxj ayewwq rjjx ) ],
		gold	=> sub { $a cmp $b },
		args	=> [ qw( string ) ],
	},
	{
		skip	=> 0,
		name	=> 'plain string no_case',
		data	=> [ qw( bdhd BDhd wxj ayewwq rjjx ) ],
		gold	=> sub { uc $a cmp uc $b },
		args	=> [ qw( no_case string ) ],
	},
	{
		skip	=> 0,
		name	=> 'fixed string',
		data	=> [ qw( bdhd BDhd wxj ayewwq rjjx ), "w\0j" ],
		gold	=> sub { $a cmp $b },
		args	=> [ qw( string fixed 6 ) ],
	},
	{
		skip	=> 0,
		name	=> 'string no_case fixed',
		data	=> [ qw( bdhd BDhd wxj ayewwq rjjx ), "w\0j" ],
		gold	=> sub { uc $a cmp uc $b },
		args	=> [ qw( string no_case fixed 6 ) ],
	},
	{
		skip	=> 0,
		name	=> 'string descending fixed',
		data	=> [ qw( bdhd BDhd wxj ayewwq rjjx ), "w\0j" ],
		gold	=> sub { $b cmp $a },
		args	=> [ qw( string descending fixed 6 ) ],
	},
	{
		skip	=> 0,
		name	=> 'string no_case descending fixed',
		data	=> [ qw( bdhd BDhd wxj ayewwq rjjx ), "w\0j" ],
		gold	=> sub { uc $b cmp uc $a },
		args	=> [ qw( string no_case descending fixed 6 ) ],
	},

	{
		skip	=> 0,
		name	=> 'varying string',
		data	=> [ qw( bdhd BDhd wxj ayewwq rjjx ), "w\0j" ],
		gold	=> sub { $a cmp $b },
		args	=> [ qw( string varying ) ],
	},
	{
		skip	=> 0,
		name	=> 'string no_case varying',
		data	=> [ qw( bdhd BDhd wxj ayewwq rjjx ), "w\0j" ],
		gold	=> sub { uc $a cmp uc $b },
		args	=> [ qw( string no_case varying ) ],
	},
	{
		skip	=> 0,
		name	=> 'string descending varying',
		data	=> [ qw( bdhd BDhd wxj ayewwq rjjx ), "w\0j" ],
		gold	=> sub { $b cmp $a },
		args	=> [ qw( string descending varying ) ],
	},
	{
		skip	=> 0,
		name	=> 'string no_case descending varying',
		data	=> [ qw( bdhd BDhd wxj ayewwq rjjx ), "w\0j" ],
		gold	=> sub { uc $b cmp uc $a },
		args	=> [ qw( string no_case descending varying ) ],
	},
] ;

common_driver( $sort_tests, \@sort_styles ) ;

exit ;

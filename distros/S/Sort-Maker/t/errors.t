#!/usr/local/bin/perl

use strict ;
use warnings ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

my $sort_tests = [

	{
		name	=> 'unknown option',
		args	=> {
			unknown => [ qw( xxx ), ],
		},
		error	=> qr/unknown/i,
	},

	{
		name	=> 'no keys',
		styles	=> [ qw( plain ) ],
		args	=> {
			no_keys => [],
		},
		error	=> qr/no keys/i,
	},

	{
		name	=> 'duplicate style',
		args	=> {
			dup_style => [qw( GRT ST ) ],
		},
		error	=> qr/style was already set/i,
	},

	{
		name	=> 'no value',
		args	=> {
			no_value => [ qw( name ) ],
		},
		error	=> qr/no value/i,
	},
	{
		name	=> 'no style',
		args	=> {
			no_style => [ qw( string ) ],
		},
		error	=> qr/no sort style/i,
	},

	{
		name	=> 'ascending and descending',
		styles	=> [ qw( plain ) ],
		args	=> {
			up_and_down => [
				string => {
					ascending	=> 1,
					descending	=> 1,
				},
			],
		},
		error	=> qr/has ascending/i,
	},

	{
		name	=> 'case and no case',
		styles	=> [ qw( plain ) ],
		args	=> {
			up_and_down => [
				string => {
					case	=> 1,
					no_case => 1,
				},
			],
		},
		error	=> qr/has case/,
	},

	{
		name	=> 'illegal code',
		styles	=> [ qw( plain ) ],
		args	=> {
			illegal	=> [
				string => 'XXX',
			],
		},
		error	=> qr/compile/,
	},

	{
		name	=> 'GRT descending string',
		styles	=> [ qw( GRT ) ],
		args	=> {
			GRT	=> [
				qw( string descending )
			],
		},
		error	=> qr/descending string/,
	},

	{
		name	=> 'array args - no value',
		styles	=> [ qw( ST ) ],
		args	=> {
			array => [
				qw( ref_in ref_out ),
				number => [
					qw(
						descending
						unsigned_float
					),
					'code',
				],
			],
		},
		error	=> qr/No value/i, 
	},

	{
		name	=> 'array args - unknown attribute',
		styles	=> [ qw( ST ) ],
		args	=> {
			array => [

				number => [
					qw(
						descending
						unsigned_float
					),
					'foobar',
				],
			],
		},
		error	=> qr/Unknown attribute/,
	},

] ;

common_driver( $sort_tests ) ;

exit ;

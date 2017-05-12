use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use Perlmazing;

my @values = (
	'3'			=> '001000',
	'8'			=> '1001',
	'2'			=> '1000',
	'0'			=> '100',
	'1'			=> '123string',
	'3'			=> '10',
	'7'			=> '20',
	'5'			=> '6',
	'bee'		=> 'code',
	'4'			=> '9',
	'ark'		=> 'ark',
	'9'			=> '4',
	'code'		=> 'bee',
	'6'			=> '5',
	'20'		=> '7',
	'10'		=> '3',
	'123string'	=> '1',
	'100'		=> '0',
	'1000'		=> '2',
	'1001'		=> '8',
	'001000'	=> '3',
);

my @sorted_by_key = (
	'0'			=> '100',
	'1'			=> '123string',
	'2'			=> '1000',
	'3'			=> '001000',
	'3'			=> '10',
	'4'			=> '9',
	'5'			=> '6',
	'6'			=> '5',
	'7'			=> '20',
	'8'			=> '1001',
	'9'			=> '4',
	'10'		=> '3',
	'20'		=> '7',
	'100'		=> '0',
	'001000'	=> '3',
	'1000'		=> '2',
	'1001'		=> '8',
	'123string'	=> '1',
	'ark'		=> 'ark',
	'bee'		=> 'code',
	'code'		=> 'bee',
);

my @result = sort_by_key @values;

is_deeply \@result, \@sorted_by_key, 'right order';
use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use Perlmazing qw(sort_by_value);

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

my @sorted_by_value = (
  '100' => '0',
  '123string' => '1',
  '1000' => '2',
  '10' => '3',
  '001000' => '3',
  '9' => '4',
  '6' => '5',
  '5' => '6',
  '20' => '7',
  '1001' => '8',
  '4' => '9',
  '3' => '10',
  '7' => '20',
  '0' => '100',
  '1' => '123string',
  '3' => '001000',
  '2' => '1000',
  '8' => '1001',
  'ark' => 'ark',
  'code' => 'bee',
  'bee' => 'code',
);

my @result = sort_by_value @values;

for (my $i = 0; $i < @result; $i += 2) {
  pl qq['$result[$i]' => '$result[$i + 1]',];
}

is_deeply \@result, \@sorted_by_value, 'right order';
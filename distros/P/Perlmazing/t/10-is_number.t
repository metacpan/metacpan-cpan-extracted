use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 12;
use Perlmazing;

my @cases = (
	[undef, 0, 'undef'],
	['', 0, 'empty'],
	['string', 0, 'string'],
	['-bareword', 0, 'minus unary operator followed by bareword'],
	[123, 1, 'number'],
	[123.34, 1, 'number'],
	['0123.34', 1, 'number'],
	['0x45', 1, 'number'],
	['-34.3', 1, 'number'],
	['1_222_333.4', 1, 'number'],
	['1.3e8', 1, 'exponential'],
	[{}, 0, 'object'],
);

for my $case (@cases) {
	$case->[0] = is_number($case->[0]) ? 1 : 0;
	is $case->[0], $case->[1], $case->[2];
}
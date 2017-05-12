use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Perlmazing;

my @cases = (
	[undef, 1, 'undef'],
	['', 1, 'empty'],
	['string', 0, 'string'],
	[123, 0, 'number'],
	[{}, 0, 'object'],
);

for my $case (@cases) {
	$case->[0] = is_empty($case->[0]) ? 1 : 0;
	is $case->[0], $case->[1], $case->[2];
}
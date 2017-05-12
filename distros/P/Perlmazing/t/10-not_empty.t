use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use Perlmazing;

my @cases = (
	['', 0, 'empty'],
	[undef, 0, 'undef'],
	['string', 1, 'string'],
);
check_cases();

sub check_cases {
	for my $c (@cases) {
		my $r = not_empty $c->[0] ? 1 : 0;
		is $r, $c->[1], $c->[2];
	}
}

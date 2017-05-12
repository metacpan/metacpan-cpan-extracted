use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 7;
use Perlmazing;
use Encode;
my $string = '¡Hola amigos! Pongan atención, esto es un poco de español';
my $encoded_string = Encode::encode('utf8', $string);

my @cases = (
	[undef, 0, 'undef'],
	['', 0, 'empty'],
	['string', 0, 'string'],
	[$encoded_string, 1, 'utf8 string'],
	[$string, 0, 'string'],
	[123, 0, 'number'],
	[{}, 0, 'object'],
);

for my $case (@cases) {
	$case->[0] = is_utf8($case->[0]) ? 1 : 0;
	is $case->[0], $case->[1], $case->[2];
}
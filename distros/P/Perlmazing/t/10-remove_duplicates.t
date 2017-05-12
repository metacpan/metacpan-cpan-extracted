use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;
use Perlmazing;

my @array = (
	1, 2, 3, 4, 5,
	      3, 4, 5, 6, 7, 8,
		        5, 7, 7, 8, 9, 10, 11,
				         8, 9, 10, 11, 12, 13, 14,
						           11, 12, 13, 14, 15,
);
my @should_be = (1..15);

my @r = remove_duplicates @array;
isnt @array, 15, '@array is untouched';
is_deeply \@r, \@should_be, 'list context works';
remove_duplicates @array;
is @array, 15, 'direct action works';
is_deeply \@array, \@should_be, '@array was processed correctly';

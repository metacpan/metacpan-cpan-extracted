use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 36;
use Perlmazing qw(commify);

my @numbers = qw(
	123
	12345
	1234.56
	-90120
	Not_a_number
);
# More extreme cases:
push @numbers, (
	'123,,456.01',
	'12,34,56',
	'12,,3,4,5.010',
	'123.456.789',
);


is $numbers[0], 123, 'Right item value on @numbers';
is $numbers[1], 12345, 'Right item value on @numbers';
is $numbers[2], 1234.56, 'Right item value on @numbers';
is $numbers[3], -90120, 'Right item value on @numbers';
is $numbers[4], 'Not_a_number', 'Right item value on @numbers';
is $numbers[5], '123,,456.01', 'Right item value on @numbers';
is $numbers[6], '12,34,56', 'Right item value on @numbers';
is $numbers[7], '12,,3,4,5.010', 'Right item value on @numbers';
is $numbers[8], '123.456.789', 'Right item value on @numbers';

my @copy = commify @numbers;
is $copy[0], 123, 'Right item value on @copy';
is $copy[1], '12,345', 'Right item value on @copy';
is $copy[2], '1,234.56', 'Right item value on @copy';
is $copy[3], '-90,120', 'Right item value on @copy';
is $copy[4], 'Not_a_number', 'Right item value on @copy';
is $copy[5], '123,456.01', 'Right item value on @copy';
is $copy[6], '123,456', 'Right item value on @copy';
is $copy[7], '12,345.010', 'Right item value on @copy';
is $copy[8], '123.456.789', 'Right item value on @copy';

is $numbers[0], 123, 'Still right item value on @numbers';
is $numbers[1], 12345, 'Still right item value on @numbers';
is $numbers[2], 1234.56, 'Still right item value on @numbers';
is $numbers[3], -90120, 'Still right item value on @numbers';
is $numbers[4], 'Not_a_number', 'Still right item value on @numbers';
is $numbers[5], '123,,456.01', 'Still right item value on @numbers';
is $numbers[6], '12,34,56', 'Still right item value on @numbers';
is $numbers[7], '12,,3,4,5.010', 'Still right item value on @numbers';
is $numbers[8], '123.456.789', 'Still right item value on @numbers';

commify @numbers;
is $numbers[0], 123, 'Right changed item value on @numbers';
is $numbers[1], '12,345', 'Right changed item value on @numbers';
is $numbers[2], '1,234.56', 'Right changed item value on @numbers';
is $numbers[3], '-90,120', 'Right changed item value on @numbers';
is $numbers[4], 'Not_a_number', 'Right changed item value on @numbers';
is $numbers[5], '123,456.01', 'Right changed item value on @numbers';
is $numbers[6], '123,456', 'Right changed item value on @numbers';
is $numbers[7], '12,345.010', 'Right changed item value on @numbers';
is $numbers[8], '123.456.789', 'Right changed item value on @numbers';

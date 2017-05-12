use strict;
use warnings;
use Test::More;

use String::Slice;

my $string = 'x' x 1000;
my $slice = '';

my $return = slice($slice, $string);
is $return, 1, 'Return value is 1';
is length($slice), 1000, 'Length matches original';
is $slice, $string, 'First slice matches string';

$return = slice($slice, $string, 100);
is $return, 1, 'Advance 100 works';
is length($slice), 900, 'Length is rest of string';

$return = slice($slice, $string, 50);
is $return, 1, 'Backup 50 works';
is length($slice), 950, 'Length is rest of string';

$return = slice($slice, $string, 250);
is $return, 1, 'Advance 200 works';
is length($slice), 750, 'Length is rest of string';

$return = slice($slice, $string, 1000);
is $return, 1, 'Advance to end works';
is length($slice), 0, 'End slice has 0 length';

$return = slice($slice, $string, 1001);
is $return, 0, 'Advance past end fails';

my $slice2 = '';
$return = slice($slice2, $string, 1000);
is $return, 1, 'Advance to end works on fresh slice';

my $slice3 = '';
$return = slice($slice3, $string, 1001);
is $return, 0, 'Advance past end fails on fresh slice';

my $string2 = "Ingy dot Net";

slice($slice, $string2, 5, 3);
is $slice, 'dot', 'substr slice with length works';

slice($slice, $string2, 9, 5);
is $slice, 'Net', 'Advance matches text';

$return = slice($slice, $string2, -100);
is $return, 0, 'Hop too far back fails';

done_testing;

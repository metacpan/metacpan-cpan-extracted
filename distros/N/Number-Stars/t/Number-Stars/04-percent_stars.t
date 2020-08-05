use strict;
use warnings;

use Number::Stars;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = Number::Stars->new;
my $ret_hr = $obj->percent_stars(50);
my $right_ret = {
	1 => 'full',
	2 => 'full',
	3 => 'full',
	4 => 'full',
	5 => 'full',
	6 => 'nothing',
	7 => 'nothing',
	8 => 'nothing',
	9 => 'nothing',
	10 => 'nothing',
};
is_deeply($ret_hr, $right_ret, 'percent value is 50.');

# Test.
$ret_hr = $obj->percent_stars(0);
$right_ret = {
	1 => 'nothing',
	2 => 'nothing',
	3 => 'nothing',
	4 => 'nothing',
	5 => 'nothing',
	6 => 'nothing',
	7 => 'nothing',
	8 => 'nothing',
	9 => 'nothing',
	10 => 'nothing',
};
is_deeply($ret_hr, $right_ret, 'percent value is 0.');

# Test.
$ret_hr = $obj->percent_stars(100);
$right_ret = {
	1 => 'full',
	2 => 'full',
	3 => 'full',
	4 => 'full',
	5 => 'full',
	6 => 'full',
	7 => 'full',
	8 => 'full',
	9 => 'full',
	10 => 'full',
};
is_deeply($ret_hr, $right_ret, 'percent value is 100.');

# Test.
$ret_hr = $obj->percent_stars(51);
$right_ret = {
	1 => 'full',
	2 => 'full',
	3 => 'full',
	4 => 'full',
	5 => 'full',
	6 => 'nothing',
	7 => 'nothing',
	8 => 'nothing',
	9 => 'nothing',
	10 => 'nothing',
};
is_deeply($ret_hr, $right_ret, 'percent value is 51.');

# Test.
$ret_hr = $obj->percent_stars(55);
$right_ret = {
	1 => 'full',
	2 => 'full',
	3 => 'full',
	4 => 'full',
	5 => 'full',
	6 => 'half',
	7 => 'nothing',
	8 => 'nothing',
	9 => 'nothing',
	10 => 'nothing',
};
is_deeply($ret_hr, $right_ret, 'percent value is 55.');

# Test.
$obj = Number::Stars->new(
	'number_of_stars' => 3,
);
$ret_hr = $obj->percent_stars(55);
$right_ret = {
	1 => 'full',
	2 => 'half',
	3 => 'nothing',
};
is_deeply($ret_hr, $right_ret, '3 stars, percent value is 55.');

use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils qw(check_number_range);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 10,
};
my $ret = check_number_range($self, 'key', 0, 10);
is($ret, undef, 'Right number is present (positive number).');

# Test.
$self = {};
$ret = check_number_range($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_number_range($self, 'key');
is($ret, undef, "Value is undefined, that's ok.");

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_number_range($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a number.\n",
	"Parameter 'key' must be a number.");
clean();

# Test.
$self = {
	'key' => 10,
};
eval {
	check_number_range($self, 'key', 11, 12);
};
is($EVAL_ERROR, "Parameter 'key' must be a number between 11 and 12.\n",
	"Parameter 'key' must be a number between 11 and 12 (10).");
clean();

# Test.
$self = {
	'key' => 10,
};
eval {
	check_number_range($self, 'key', 8, 9);
};
is($EVAL_ERROR, "Parameter 'key' must be a number between 8 and 9.\n",
	"Parameter 'key' must be a number between 8 and 9 (10).");
clean();

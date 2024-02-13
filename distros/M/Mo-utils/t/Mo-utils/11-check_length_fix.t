use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils qw(check_length_fix);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_length_fix($self, 'key', 2);
};
is($EVAL_ERROR, "Parameter 'key' has length different than '2'.\n",
	"Parameter 'key' has length different than '2'.");
clean();

# Test.
$self = {
	'key' => 'foo',
};
my $ret = check_length_fix($self, 'key', 3);
is($ret, undef, 'Right length of value is present (foo and 3).');

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_length_fix($self, 'key', 4);
};
is($EVAL_ERROR, "Parameter 'key' has length different than '4'.\n",
	"Parameter 'key' has length different than '4'.");
clean();

# Test.
$self = {};
$ret = check_length_fix($self, 'key', 4);
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_length_fix($self, 'key', 4);
is($ret, undef, 'Right length of value is present (undef value).');

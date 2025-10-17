use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Array qw(check_array_strings);
use Readonly;
use Test::More 'tests' => 10;
use Test::NoWarnings;

Readonly::Array our @POSSIBLE_STRINGS => qw(foo bar);

# Test.
my $self = {
	'key' => ['foo'],
};
my $ret = check_array_strings($self, 'key', \@POSSIBLE_STRINGS);
is($ret, undef, 'Right structure (one of strings).');

# Test.
$self = {
	'key' => [],
};
$ret = check_array_strings($self, 'key', \@POSSIBLE_STRINGS);
is($ret, undef, 'Right structure (none of strings).');

# Test.
$self = {};
$ret = check_array_strings($self, 'key', \@POSSIBLE_STRINGS);
is($ret, undef, 'Right structure (no key).');

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_array_strings($self, 'key', \@POSSIBLE_STRINGS);
};
is($EVAL_ERROR, "Parameter 'key' must be a array.\n",
	"Parameter 'key' must be a array (string).");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_array_strings($self, 'key', \@POSSIBLE_STRINGS);
};
is($EVAL_ERROR, "Parameter 'key' must be a array.\n",
	"Parameter 'key' must be a array (undef).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_array_strings($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must have strings definition.\n",
	"Parameter 'key' must have strings definition (no definition).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_array_strings($self, 'key', 'bad');
};
is($EVAL_ERROR, "Parameter 'key' must have right string definition.\n",
	"Parameter 'key' must have right string definition (bad).");
clean();

# Test.
$self = {
	'key' => [\'bad'],
};
eval {
	check_array_strings($self, 'key', \@POSSIBLE_STRINGS);
};
is($EVAL_ERROR, "Parameter 'key' must contain a list of strings.\n",
	"Parameter 'key' must contain a list of strings (reference to scalar).");
clean();

# Test.
$self = {
	'key' => ['foo', 'bar', 'bad'],
};
eval {
	check_array_strings($self, 'key', \@POSSIBLE_STRINGS);
};
is($EVAL_ERROR, "Parameter 'key' must be one of the defined strings.\n",
	"Parameter 'key' must be one of the defined strings (bad string).");
clean();


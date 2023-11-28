use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils qw(check_array_required);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_array_required($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a array.\n",
	"Parameter 'key' must be a array.");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_array_required($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' with array must have at least one item.\n",
	"Parameter 'key' with array must have at least one item.");
clean();

# Test.
$self = {};
eval {
	check_array_required($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required.");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_array_required($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a array.\n",
	"Parameter 'key' must be a array.");
clean();

# Test.
$self = {
	'key' => ['value'],
};
my $ret = check_array_required($self, 'key');
is($ret, undef, 'Right structure.');


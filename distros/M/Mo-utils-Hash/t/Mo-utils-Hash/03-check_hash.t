use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Hash qw(check_hash);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => {},
};
my $ret = check_hash($self, 'key');
is($ret, undef, 'Right reference to hash is present ({}).');

# Test.
$self = {};
$ret = check_hash($self, 'key');
is($ret, undef, 'Right time is present (key is not exists).');

# Test.
$self = {
	'key' => undef,
};
eval {
	check_hash($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' isn't hash reference.\n",
	"Parameter 'key' isn't hash reference (undef).");
clean();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_hash($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' isn't hash reference.\n",
	"Parameter 'key' isn't hash reference (foo).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_hash($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' isn't hash reference.\n",
	"Parameter 'key' isn't hash reference ([]).");
clean();

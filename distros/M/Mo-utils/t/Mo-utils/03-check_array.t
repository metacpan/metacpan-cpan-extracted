use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils qw(check_array);
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_array($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a array.\n",
	"Parameter 'key' must be a array.");
clean();

# Test.
$self = {
	'key' => ['foo'],
};
my $ret = check_array($self, 'key');
is($ret, undef, 'Right structure.');

# Test.
$self = {};
$ret = check_array($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
eval {
	check_array($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a array.\n",
	"Parameter 'key' must be a array.");
clean();

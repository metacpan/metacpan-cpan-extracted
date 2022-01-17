use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::MockObject;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Mo::utils qw(check_array);

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

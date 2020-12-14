use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Mo::utils qw(check_array_object check_required);

# Test.
my $self = {
	'key' => undef,
};
eval {
	check_required($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required.");
clean();

# Test.
$self = {
	'key' => 'foo',
};
my $ret = check_required($self, 'key');
is($ret, undef, 'Required value is present.');

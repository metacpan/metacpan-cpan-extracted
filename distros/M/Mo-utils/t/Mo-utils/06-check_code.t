use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils qw(check_code);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => sub {},
};
my $ret = check_code($self, 'key');
is($ret, undef, 'Right code value.');

# Test.
$self = {
	'key' => 'bad',
};
eval {
	check_code($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a code.\n",
	"Parameter 'key' must be a code.");
clean();

# Test.
$self = {};
$ret = check_code($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_code($self, 'key');
is($ret, undef, 'Right undefined value.');

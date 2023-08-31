use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::EAN qw(check_ean);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_ean($self, 'key');
};
is($EVAL_ERROR, "EAN code doesn't valid.\n",
	"EAN code doesn't valid.");
clean();

# Test.
$self = {
	'key' => '8590786020177',
};
my $ret = check_ean($self, 'key');
is($ret, undef, 'Right ean is present (8590786020177).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_ean($self, 'key');
is($ret, undef, 'Right ean is present (undef).');

# Test.
$self = {};
$ret = check_ean($self, 'key');
is($ret, undef, 'Right ean is present (key is not exists).');

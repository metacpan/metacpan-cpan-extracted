use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Language qw(check_language);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_language($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid ISO 639-1 code.\n",
	"Parameter 'key' doesn't contain valid ISO 639-1 code (foo).");
clean();

# Test.
$self = {
	'key' => 'xx',
};
eval {
	check_language($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid ISO 639-1 code.\n",
	"Parameter 'key' doesn't contain valid ISO 639-1 code (xx).");
clean();

# Test.
$self = {
	'key' => 'en',
};
my $ret = check_language($self, 'key');
is($ret, undef, 'Right language is present (en - 639-1).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_language($self, 'key');
is($ret, undef, 'Right language is present (undef).');

# Test.
$self = {};
$ret = check_language($self, 'key');
is($ret, undef, 'Right language is present (key is not exists).');

use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Country qw(check_country_3166_1_alpha_2);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'cz',
};
my $ret = check_country_3166_1_alpha_2($self, 'key');
is($ret, undef, 'Right country is present (cz).');

# Test.
$self = {
	'key' => 'CZ',
};
$ret = check_country_3166_1_alpha_2($self, 'key');
is($ret, undef, 'Right country is present (CZ).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_country_3166_1_alpha_2($self, 'key');
is($ret, undef, 'Right country is present (undef).');

# Test.
$self = {};
$ret = check_country_3166_1_alpha_2($self, 'key');
is($ret, undef, 'Right country is present (key is not exists).');

# Test.
$self = {
	'key' => 'xx',
};
eval {
	check_country_3166_1_alpha_2($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid ISO 3166-1 alpha-2 code.\n",
	"Parameter 'key' doesn't contain valid ISO 3166-1 alpha-2 code (xx).");
clean();


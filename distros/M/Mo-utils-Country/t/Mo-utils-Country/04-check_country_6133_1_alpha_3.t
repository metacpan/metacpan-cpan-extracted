use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Country qw(check_country_3166_1_alpha_3);
use Test::More 'tests' => 5;
use Test::NoWarnings;

my # Test.
$self = {
	'key' => 'cze',
};
my $ret = check_country_3166_1_alpha_3($self, 'key');
is($ret, undef, 'Right country is present (cze).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_country_3166_1_alpha_3($self, 'key');
is($ret, undef, 'Right country is present (undef).');

# Test.
$self = {};
$ret = check_country_3166_1_alpha_3($self, 'key');
is($ret, undef, 'Right country is present (key is not exists).');

# Test.
$self = {
	'key' => 'xxx',
};
eval {
	check_country_3166_1_alpha_3($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid ISO 3166-1 alpha-3 code.\n",
	"Parameter 'key' doesn't contain valid ISO 3166-1 alpha-3 code (xxx).");
clean();


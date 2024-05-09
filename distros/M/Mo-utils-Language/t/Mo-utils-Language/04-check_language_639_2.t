use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Language qw(check_language_639_2);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'xxx',
};
eval {
	check_language_639_2($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid ISO 639-2 code.\n",
	"Parameter 'key' doesn't contain valid ISO 639-2 code (xxx).");
clean();

# Test.
$self = {
	'key' => 'eng',
};
my $ret = check_language_639_2($self, 'key');
is($ret, undef, 'Right language is present (eng - 639-2).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_language_639_2($self, 'key');
is($ret, undef, 'Right language is present (undef).');

# Test.
$self = {};
$ret = check_language_639_2($self, 'key');
is($ret, undef, 'Right language is present (key is not exists).');

use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Unicode qw(check_unicode_script);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'Thai',
};
my $ret = check_unicode_script($self, 'key');
is($ret, undef, 'Right Unicode script is present (Thai).');

# Test.
$self = {};
$ret = check_unicode_script($self, 'key');
is($ret, undef, 'No Unicode script is present.');

# Test.
$self = {
	'key' => 'bad',
};
eval {
	check_unicode_script($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' contains invalid Unicode script.\n",
	"Parameter 'key' contains invalid Unicode script (bad).");
clean();

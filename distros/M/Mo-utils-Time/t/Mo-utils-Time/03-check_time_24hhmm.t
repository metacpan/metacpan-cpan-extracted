use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Time qw(check_time_24hhmm);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => '12:30',
};
my $ret = check_time_24hhmm($self, 'key');
is($ret, undef, 'Right time is present (12:30).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_time_24hhmm($self, 'key');
is($ret, undef, 'Right time is present (undef).');

# Test.
$self = {};
$ret = check_time_24hhmm($self, 'key');
is($ret, undef, 'Right time is present (key is not exists).');

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_time_24hhmm($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid time in HH:MM format.\n",
	"Parameter 'key' doesn't contain valid time in HH:MM format (foo).");
clean();

# Test.
$self = {
	'key' => '32:12',
};
eval {
	check_time_24hhmm($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid hour in HH:MM time format.\n",
	"Parameter 'key' doesn't contain valid hour in HH:MM time format (32:12).");
clean();

# Test.
$self = {
	'key' => '12:72',
};
eval {
	check_time_24hhmm($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid minute in HH:MM time format.\n",
	"Parameter 'key' doesn't contain valid minute in HH:MM time format (12:72).");
clean();

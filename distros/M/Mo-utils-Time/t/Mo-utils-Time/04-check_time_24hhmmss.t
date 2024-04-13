use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Time qw(check_time_24hhmmss);
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => '12:30:12',
};
my $ret = check_time_24hhmmss($self, 'key');
is($ret, undef, 'Right time is present (12:30:12).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_time_24hhmmss($self, 'key');
is($ret, undef, 'Right time is present (undef).');

# Test.
$self = {};
$ret = check_time_24hhmmss($self, 'key');
is($ret, undef, 'Right time is present (key is not exists).');

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_time_24hhmmss($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid time in HH:MM:SS format.\n",
	"Parameter 'key' doesn't contain valid time in HH:MM:SS format (foo).");
clean();

# Test.
$self = {
	'key' => '32:12:12',
};
eval {
	check_time_24hhmmss($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid hour in HH:MM:SS time format.\n",
	"Parameter 'key' doesn't contain valid hour in HH:MM:SS time format (32:12:12).");
clean();

# Test.
$self = {
	'key' => '12:72:12',
};
eval {
	check_time_24hhmmss($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid minute in HH:MM:SS time format.\n",
	"Parameter 'key' doesn't contain valid minute in HH:MM:SS time format (12:72:12).");
clean();

# Test.
$self = {
	'key' => '12:12:72',
};
eval {
	check_time_24hhmmss($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid second in HH:MM:SS time format.\n",
	"Parameter 'key' doesn't contain valid second in HH:MM:SS time format (12:12:72).");
clean();

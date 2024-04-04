use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::TimeZone qw(check_timezone_iana);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'Europe/Prague',
};
my $ret = check_timezone_iana($self, 'key');
is($ret, undef, 'Right timezone is present (Europe/Prague).');

# Test.
$self = {
	'key' => 'Europe/Bratislava',
};
$ret = check_timezone_iana($self, 'key');
is($ret, undef, 'Right timezone is present (Europe/Bratislava).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_timezone_iana($self, 'key');
is($ret, undef, 'Right timezone is present (undef).');

# Test.
$self = {};
$ret = check_timezone_iana($self, 'key');
is($ret, undef, 'Right timezone is present (key is not exists).');

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_timezone_iana($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid IANA timezone code.\n",
	"Parameter 'key' doesn't contain valid IANA timezone code (foo).");
clean();

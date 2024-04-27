use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::Email qw(check_email);
use Readonly;
use Test::More 'tests' => 7;
use Test::NoWarnings;

Readonly::Array our @RIGHT_EMAILS => qw(
	michal.josef.spacek@gmail.com
	Michal.Josef.Spacek@gmail.com
);

# Test.
my ($ret, $self);
foreach my $right_email (@RIGHT_EMAILS) {
	$self = {
		'key' => $right_email,
	};
	$ret = check_email($self, 'key');
	is($ret, undef, 'Right email is present ('.$right_email.').');
}

# Test.
$self = {};
$ret = check_email($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_email($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid email.\n",
	"Parameter 'key' doesn't contain valid email.");
my $err_msg_hr = err_msg_hr();
is(keys %{$err_msg_hr}, 1, 'One error parameter.');
is($err_msg_hr->{'Value'}, 'foo', 'Test error parameter (Value: foo).');
clean();

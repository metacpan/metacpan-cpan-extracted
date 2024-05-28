use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils qw(check_number_id);
use Readonly;
use Test::More 'tests' => 12;
use Test::NoWarnings;

Readonly::Array our @BAD_IDS => qw(
	10.0001
	-10
	0
	foo
);

# Test.
my $self = {
	'key' => 10,
};
my $ret = check_number_id($self, 'key');
is($ret, undef, 'Right number is present (natural number).');

# Test.
$self = {};
$ret = check_number_id($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_number_id($self, 'key');
is($ret, undef, "Value is undefined, that's ok.");

foreach my $bad_id (@BAD_IDS) {
	$self = {
		'key' => $bad_id,
	};
	eval {
		check_number_id($self, 'key');
	};
	is($EVAL_ERROR, "Parameter 'key' must be a natural number.\n",
		"Parameter 'key' must be a natural number. Value is '$bad_id'.");
	my $err_msg_hr = err_msg_hr();
	is($err_msg_hr->{'Value'}, $bad_id, 'Test error parameter (Value: '.$bad_id.').');
	clean();
}

use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Email qw(check_email);
use Readonly;
use Test::More 'tests' => 5;
use Test::NoWarnings;

Readonly::Array our @RIGHT_EMAILS => qw(
	michal.josef.spacek@gmail.com
	Michal.Josef.Spacek@gmail.com
);

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_email($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain valid email.\n",
	"Parameter 'key' doesn't contain valid email.");
clean();

# Test.
my $ret;
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

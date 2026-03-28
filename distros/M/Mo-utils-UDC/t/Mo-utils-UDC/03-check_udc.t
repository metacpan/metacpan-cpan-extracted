use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::UDC qw(check_udc);
use Readonly;
use Test::More 'tests' => 14;
use Test::NoWarnings;

Readonly::Array our @RIGHT_UDCS => qw(
	0/9
	821.111(73)-31"19"
	621.397:621.395
	(075)
	"19"
	=111
);
Readonly::Array our @BAD_UDCS => qw(
	bad
	821.111+
	:821.111
	+821.111
	-31
);

# Test.
my ($ret, $self);
foreach my $right_udc (@RIGHT_UDCS) {
	$self = {
		'key' => $right_udc,
	};
	$ret = check_udc($self, 'key');
	is($ret, undef, 'Right udc is present ('.$right_udc.').');
}

# Test.
$self = {};
$ret = check_udc($self, 'key');
is($ret, undef, 'Right udc is present (no key).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_udc($self, 'key');
is($ret, undef, 'Right udc is present (undef).');

# Test.
foreach my $bad_udc (@BAD_UDCS) {
	$self = {
		'key' => $bad_udc,
	};
	eval {
		check_udc($self, 'key');
	};
	is($EVAL_ERROR, "Parameter 'key' doesn't contain valid Universal Decimal Classification string.\n",
		"Parameter 'key' doesn't contain valid Universal Decimal Classification string ($bad_udc).");
	clean();
}

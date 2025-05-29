use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::URI qw(check_urn);
use Readonly;
use Test::More 'tests' => 11;
use Test::NoWarnings;

Readonly::Array our @RIGHT_URNS => qw(
	urn:isbn:0451450523
	urn:oasis:names:specification:docbook:dtd:xml:4.1.2
	urn:uuid:c37d55a0-d957-4020-9923-44314f87e192
	urn:nbn:cz:nk-0046wn
);
Readonly::Array our @BAD_URNS => qw(
	foo
	urn:
	urn:bad
	http://skim.cz
);

# Test.
my ($ret, $self);
foreach my $right_urn (@RIGHT_URNS) {
	$self = {
		'key' => $right_urn,
	};
	$ret = check_urn($self, 'key');
	is($ret, undef, 'Right URN is present ('.$right_urn.').');
}

# Test.
$self = {};
$ret = check_urn($self, 'key');
is($ret, undef, 'Right URN is present (no key).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_urn($self, 'key');
is($ret, undef, 'Right URN is present (undef).');

# Test.
foreach my $bad_urn (@BAD_URNS) {
	$self = {
		'key' => $bad_urn,
	};
	eval {
		check_urn($self, 'key');
	};
	is($EVAL_ERROR, "Parameter 'key' doesn't contain valid URN.\n",
		"Parameter 'key' doesn't contain valid URN ($bad_urn).");
	clean();
}

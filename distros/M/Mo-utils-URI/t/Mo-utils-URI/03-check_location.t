use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::URI qw(check_location);
use Readonly;
use Test::More 'tests' => 10;
use Test::NoWarnings;

Readonly::Array our @RIGHT_LOCATIONS => qw(
	http://skim.cz
	https://skim.cz
	ftp://ftp.example.com/archive.zip
	/images/image.gif
	image.gif
	action?method=get&foo=bar
	?method=get&foo=bar
);
Readonly::Array our @BAD_LOCATIONS => qw(
	urn:isbn:0451450523
);

# Test.
my ($ret, $self);
foreach my $right_url (@RIGHT_LOCATIONS) {
	$self = {
		'key' => $right_url,
	};
	$ret = check_location($self, 'key');
	is($ret, undef, 'Right location is present ('.$right_url.').');
}

# Test.
$self = {};
$ret = check_location($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
foreach my $bad_location (@BAD_LOCATIONS) {
	$self = {
		'key' => $bad_location,
	};
	eval {
		check_location($self, 'key');
	};
	is($EVAL_ERROR, "Parameter 'key' doesn't contain valid location.\n",
		"Parameter 'key' doesn't contain valid location ($bad_location).");
	clean();
}

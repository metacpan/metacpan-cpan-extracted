use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::URI qw(check_url);
use Readonly;
use Test::More 'tests' => 7;
use Test::NoWarnings;

Readonly::Array our @RIGHT_URLS => qw(
	http://skim.cz
	https://skim.cz
	ftp://ftp.example.com/archive.zip
);
Readonly::Array our @BAD_URLS => qw(
	foo
	urn:isbn:0451450523
);

# Test.
my ($ret, $self);
foreach my $right_url (@RIGHT_URLS) {
	$self = {
		'key' => $right_url,
	};
	$ret = check_url($self, 'key');
	is($ret, undef, 'Right URL is present ('.$right_url.').');
}

# Test.
$self = {};
$ret = check_url($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
foreach my $bad_url (@BAD_URLS) {
	$self = {
		'key' => $bad_url,
	};
	eval {
		check_url($self, 'key');
	};
	is($EVAL_ERROR, "Parameter 'key' doesn't contain valid URL.\n",
		"Parameter 'key' doesn't contain valid URI ($bad_url).");
	clean();
}

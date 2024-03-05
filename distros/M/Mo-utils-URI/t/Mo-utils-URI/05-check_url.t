use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::URI qw(check_url);
use Readonly;
use Test::More 'tests' => 12;
use Test::NoWarnings;

Readonly::Array our @RIGHT_URLS => qw(
	http://skim.cz
	https://skim.cz
	ftp://ftp.example.com/archive.zip
	telnet://192.0.2.16:80/
	ldap://[2001:db8::7]/c=GB?objectClass?one
);
Readonly::Array our @BAD_URLS => qw(
	foo
	urn:isbn:0451450523
	mailto:John.Doe@example.com
	tel:+1-816-555-1212
	news:comp.infosystems.www.servers.unix
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

use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::URI qw(check_uri);
use Readonly;
use Test::More 'tests' => 15;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

Readonly::Array our @RIGHT_URIS => qw(
	http://skim.cz
	https://skim.cz
	ftp://ftp.is.co.za/rfc/rfc1808.txt
	http://www.ietf.org/rfc/rfc2396.txt
	ldap://[2001:db8::7]/c=GB?objectClass?one
	mailto:John.Doe@example.com
	news:comp.infosystems.www.servers.unix
	tel:+1-816-555-1212
	telnet://192.0.2.16:80/
	urn:isbn:0451450523
	urn:oasis:names:specification:docbook:dtd:xml:4.1.2
);
Readonly::Array our @BAD_URIS => (
	'foo',
	decode_utf8('https://michal.josef.špaček'),
);

# Test.
my ($ret, $self);
foreach my $right_uri (@RIGHT_URIS) {
	$self = {
		'key' => $right_uri,
	};
	$ret = check_uri($self, 'key');
	is($ret, undef, 'Right URI is present ('.$right_uri.').');
}

# Test.
$self = {};
$ret = check_uri($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
foreach my $bad_uri (@BAD_URIS) {
	$self = {
		'key' => $bad_uri,
	};
	eval {
		check_uri($self, 'key');
	};
	is($EVAL_ERROR, "Parameter 'key' doesn't contain valid URI.\n",
		encode_utf8("Parameter 'key' doesn't contain valid URI ($bad_uri)."));
	clean();
}

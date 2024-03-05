use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::IRI qw(check_iri);
use Readonly;
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

Readonly::Array our @RIGHT_IRIS => (
	'http://skim.cz',
	'https://skim.cz',
	'ftp://ftp.is.co.za/rfc/rfc1808.txt',
	'http://www.ietf.org/rfc/rfc2396.txt',
	decode_utf8('https://michal.josef.špaček'),
);
Readonly::Array our @BAD_IRIS => qw(
	foo
);

# Test.
my ($ret, $self);
foreach my $right_iri (@RIGHT_IRIS) {
	$self = {
		'key' => $right_iri,
	};
	$ret = check_iri($self, 'key');
	is($ret, undef, encode_utf8('Right IRI is present ('.$right_iri.').'));
}

# Test.
$self = {};
$ret = check_iri($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
foreach my $bad_iri (@BAD_IRIS) {
	$self = {
		'key' => $bad_iri,
	};
	eval {
		check_iri($self, 'key');
	};
	is($EVAL_ERROR, "Parameter 'key' doesn't contain valid IRI.\n",
		"Parameter 'key' doesn't contain valid IRI ($bad_iri).");
	clean();
}

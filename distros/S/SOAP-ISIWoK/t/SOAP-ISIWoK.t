# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SOAP-ISIWoK.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 10;
BEGIN { use_ok('SOAP::ISIWoK') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# these are the editions Southampton has subs for
my $isi = SOAP::ISIWoK->new(
	collections => {
		BIOABS => [],
		CABI => [],
		WOS => [qw(SCI SSCI AHCI ISTP ISSHP)],
	},
);
ok($isi);

my $som;
my $result;

$som = $isi->authenticate;
ok(!$som->fault, fault_message('authenticate', $som));
diag $som->result;

$som = $isi->search('AU = (Brody)');
ok(!$som->fault, fault_message('search', $som));
#diag Data::Dumper::Dumper($som->result);

$som = $isi->search('AU = (Brody)',
	offset => 5,
	max => 20,
	sort => 'PY',
	fields => [qw( titles abstract )],
	options => {
		RecordIDs => 'On',
	},
);
ok(!$som->fault, fault_message('search with opts', $som));

$result = $som->result;

$som = $isi->retrieve($result->{queryId},
	offset => 21,
	max => 20,
	sort => 'PY',
	options => {
		RecordIDs => 'On',
	},
);
ok(!$som->fault, fault_message('retrieve', $som));
ok($result->{optionValue}{value}[0], 'missing record id');

$result = $som->result;

my $uid = 'WOS:A1970Y327100002';

$som = $isi->retrieveById($uid,
	options => {
		RecordIDs => 'On',
	},
);
ok(!$som->fault, fault_message('retrieveById', $som));

$result = $som->result;

$som = $isi->citedReferences($uid);
ok(!$som->fault, fault_message('citedReferences', $som));

$result = $som->result;

#delete $result->{records};
#diag Dumper($result);

ok(1);

sub fault_message
{
	my ($msg, $som) = @_;

	return $msg if !$som->fault;

	return sprintf("%s (%s): %s",
		$msg,
		$som->faultcode,
		$som->faultstring,
	);
}

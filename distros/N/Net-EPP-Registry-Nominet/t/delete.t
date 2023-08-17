#
#===============================================================================
#
#         FILE:  delete.t
#
#  DESCRIPTION:  Test of EPP delete operation
#
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  04/04/13 18:09:48
#===============================================================================

use strict;
use warnings FATAL => 'recursion';

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 7;
} else {
	plan skip_all => 'Cannot connect to testbed without NOMTAG and NOMPASS';
}

use Net::EPP::Registry::Nominet;

my $epp = new_ok ('Net::EPP::Registry::Nominet', [ ote => 1,
	user => $ENV{NOMTAG}, pass => $ENV{NOMPASS}, debug =>
	$ENV{DEBUG_TEST} || 0 ] );

is ($Net::EPP::Registry::Nominet::Code, 1000, 'Logged in');

warn $Net::EPP::Registry::Nominet::Error if
$Net::EPP::Registry::Nominet::Error;

BAIL_OUT ("Cannot login to EPP server") if
		$Net::EPP::Registry::Nominet::Error;

my $tag = lc $ENV{NOMTAG};
my $now = time ();
my $domtogo = "del-$now-$tag.co.uk";
my $registrant = {
		id			=>	"reg-$now",
		name		=>	'Acme Domain Company',
		'trad-name'	=>	'Domsplosion',
		'type'		=>	'LTD',
		'co-no'		=>	'12345678',
		'postalInfo'=>	{ loc => {
			'name'		=>	'Big Red Hippopotamus',
			'org'		=>	'Acme Domain Company',
			'addr'		=>	{
				'street'	=>	['555 Carlton Heights'],
				'city'		=>	'Testington',
				'sp'		=>	'Testshire',
				'pc'		=>	'XL99 9XL',
				'cc'		=>	'GB'
			}
		}},
		'voice'		=>	'+44.1234567890',
		'email'		=>	'bigred@example.com'
};
my $domain = {
	name	=>	$domtogo,
	period	=>	"2",
	registrant	=>	$registrant,
	nameservers	=>	{
		'nsname0'	=>	"ns1.demetrius-$tag.co.uk"
	}
};
my ($expiry, $reason, $regid) = $epp->register ($domain);
ok $expiry, "$domtogo registered for deletion test" or
	diag ($epp->get_code, $reason);

is ($epp->delete_domain('foo.bar.uk'), undef, "Delete non-existent domain");
my $res = $epp->delete_domain($domtogo);
# This should either work or fail with V175 code 2201
# Testing for it is rather a hack because our code isn't used for this
# at all - it is handled upstream. We should bring some of it down for
# uniformity.
if (defined $res) {
	is ($res, 1, "Delete success");
} else {
	is ($Net::EPP::Simple::Code, 2201, "Delete unauthorised");
	#diag "Msg: " . $Net::EPP::Simple::Message;
}

SKIP: {
	skip "Deletion AUP Exceeded", 1 unless defined $res;
	($res) = $epp->check_domain ($domtogo);
	is ($res, 1, "Non-existent domain check: $domtogo");
}

ok ($epp->logout(), 'Logout successful');

exit;

#
#===============================================================================
#
#         FILE:  release.t
#
#  DESCRIPTION:  Test of EPP release operation
#
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  04/04/13 17:30:19
#===============================================================================

use strict;
use warnings;

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 10;
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
my $newtag = substr ($ENV{NOMTAG}, 0, 15) . '_';

my $domtogo = ("foo-openstrike.co.uk");

is ($epp->release_domain($domtogo, $newtag), 0, "Release bad dom to $newtag");
like ($epp->get_reason (), qr/V096/, "Release bad dom to $newtag - reason");
is ($epp->release_domain($domtogo, 'NOTAREALTAG'), 0, "Release bad dom to wrong tag");
like ($epp->get_reason (), qr/V016/, "Release bad dom to wrong tag - reason");

# Register unique dom just to transfer out.

my $now = time ();
$domtogo = "go-$now-$tag.co.uk";
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
my ($expiry) = $epp->register ($domain);

# Cannot detag a domain within 30 days of registration
is ($epp->release_domain($domtogo, 'DETAGGED'), 0, "Release $domtogo to DETAGGED");
like ($epp->get_reason (), qr/V101/, "Release to DETAGGED - reason");

# Can release it to a valid receiving tag, however
is ($epp->release_domain($domtogo, $newtag), 1, "Release $domtogo to $newtag") or
	diag ($epp->get_message, $epp->get_code, $epp->get_error);

ok ($epp->logout(), 'Logout successful');

exit;

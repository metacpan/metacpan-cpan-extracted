#
#===============================================================================
#
#         FILE:  release.t
#
#  DESCRIPTION:  Test of EPP release operation
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      VERSION:  $Id: release.t,v 1.2 2015/08/17 15:40:21 pete Exp $
#      CREATED:  04/04/13 17:30:19
#     REVISION:  $Revision: 1.2 $
#===============================================================================

use strict;
use warnings;

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 10;
} else {
	plan skip_all => 'Cannot connect to testbed without NOMTAG and NOMPASS';
}

use lib './lib';
use Net::EPP::Registry::Nominet;

my $epp = new_ok ('Net::EPP::Registry::Nominet', [ test => 1,
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

is ($epp->release_domain($domtogo, 'NOMINET'), 0, "Release to NOMINET");
like ($epp->get_reason (), qr/V055/, "Release to NOMINET - reason");
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
		'opt-out'	=>	'n',
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
		'nsname0'	=>	"ns1.demetrius-$tag.co.uk",
		'nsname1'	=>	"ns1.ariel-$tag.co.uk"
	}
};
my ($expiry, $reason, $regid) = $epp->register ($domain);
is ($epp->release_domain($domtogo, $newtag), 1, "Release to $newtag");

ok ($epp->logout(), 'Logout successful');

exit;

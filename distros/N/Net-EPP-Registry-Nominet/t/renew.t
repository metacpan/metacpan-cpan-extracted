#
#===============================================================================
#
#         FILE:  renew.t
#
#  DESCRIPTION:  Test of renewals
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      VERSION:  $Id: renew.t,v 1.6 2015/08/21 16:11:42 pete Exp $
#      CREATED:  04/02/13 17:15:33
#     REVISION:  $Revision: 1.6 $
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

# Register unique dom just to renew and unrenew.

my $now = time ();
my $newdom = "renew-$now-$tag.co.uk";
my $registrant = {
		id			=>	"reg-r-$now",
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
	name	=>	$newdom,
	period	=>	"2",
	registrant	=>	$registrant,
	nameservers	=>	{
		'nsname0'	=>	"ns1.demetrius-$tag.co.uk",
		'nsname1'	=>	"ns1.ariel-$tag.co.uk"
	}
};
my ($expiry, $reason, $regid) = $epp->register ($domain);
unless ($expiry) { diag $reason; }
#else { diag $newdom; }

my $renewit = {name => "duncan-$tag.co.uk"};
my $newexpiry = $epp->renew ($renewit) || $epp->get_reason;

like ($newexpiry, qr/^\d\d\d\d-|^V128 /, 'Plain renewal');

$renewit = {name => "horatio-$tag.co.uk", period => 10};
$newexpiry = $epp->renew ($renewit) ||
	$epp->get_reason;

like ($newexpiry, qr/^V128 /, '10-year renewal too long');

$renewit = {name => $newdom, period => 5};
$newexpiry = $epp->renew ($renewit);
like ($newexpiry, qr/^\d\d\d\d-\d\d-\d\d/, 'Renewal success');

# Unrenew here
my $datesref = undef;
my $dom = "lysander-$tag.co.uk";

$datesref = $epp->unrenew ($dom, "duncan-$tag.co.uk");
$reason = $epp->get_reason;
like ($datesref->{$dom} || $reason, qr/^\d\d\d\d-|V270 /, 'Multiple domain unrenewal') or warn "Reason: ". $epp->get_reason . "\n";

$datesref = $epp->unrenew ("macbeth-$tag.plc.uk");
$reason = $epp->get_reason;
like ($datesref->{$dom} || $reason, qr/^V265 /, 'Single domain unrenewal') or warn "Reason: ". $epp->get_reason . "\n";

$datesref = $epp->unrenew ("wotnodomain-$tag.me.uk");
$reason = $epp->get_reason;
like ($datesref->{$dom} || $reason, qr/^V208 /, 'Non-existent domain unrenewal') or warn "Reason: ". $epp->get_reason . "\n";

# Even though we've registered and renewed this successfully, it cannot
# be unrenewed. Nominet's systems merge the registration and renewal
# behind the scenes so that as far as they are concerned it hasn't been
# renewed at all.
$datesref = $epp->unrenew ($newdom);
$reason = $epp->get_reason;
like ($reason, qr/^V265 /, 'Cannot unrenew a non-renewed domain');

ok ($epp->logout(), 'Logout successful');

exit;


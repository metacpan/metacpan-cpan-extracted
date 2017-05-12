#
#===============================================================================
#
#         FILE:  register.t
#
#  DESCRIPTION:  Test of domain registration
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      VERSION:  $Id: register.t,v 1.4 2014/10/31 17:20:51 pete Exp $
#      CREATED:  06/02/13 16:30:11
#     REVISION:  $Revision: 1.4 $
#===============================================================================

use strict;
use warnings;

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 25;
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
my $now = time ();
warn "stamp = $now" if $ENV{DEBUG_TEST};
my $registrant = {
		id			=>	"reg-$now",
		name		=>	'Acme Domain Company',
		'trad-name'	=>	'Domsplosion',
		'type'		=>	'LTD',
		'co-no'		=>	'12345678',
		'opt-out'	=>	'n',
		'postalInfo'=>	{ loc => {
			'name'		=>	'Quasi Modoe',
			'org'		=>	'Acme Domain Company',
			'addr'		=>	{
				'street'	=>	['555 Carlton Heights', 'Highfield'],
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
	name	=>	"$now-$tag.co.uk",
	period	=>	"5",
	registrant	=>	$registrant,
	nameservers	=>	{
		'nsname0'	=>	"ns1.demetrius-$tag.co.uk",
		'nsname1'	=>	"ns1.ariel-$tag.co.uk"
	},
	secDNS	=>	[
		{
			keyTag     => 25103,
			alg	       => 5,
			digestType => 1,
			digest     => '8A9CEBB665B78E0142F1CEF47CC9F4205F600685'
		}
	]
};

my ($res) = $epp->register ($domain);

ok ($res, 'Domain registration with new account/contact');
like ($res->{expiry}, qr/^\d\d\d\d-/, 'Domain registration with new account/contact: expiry match');
is ($res->{regid}, "reg-$now", 'Domain registration with new account/contact: reg id match');

# Try again
$domain->{name} = "$now-b-$tag.co.uk";
$domain->{registrant} = $registrant;
($res) = $epp->register ($domain);
is ($epp->get_code, 2302, 'Domain registration with duplicate account/contact');
	
# Try again
$domain->{registrant} = '_not_a_reg_';
($res) = $epp->register ($domain);
is ($epp->get_code, 2201, 'Domain registration with non-existant account/contact');
	
# Reg new domain to existing contact
$domain->{registrant} = $registrant->{id};
($res) = $epp->register ($domain);
is ($epp->get_code, 1000, 'Domain registration with old account/contact');

# Try same with other SLDs
for my $sld (qw/org.uk me.uk uk/) {
	$domain->{name} = "$now-b-$tag.$sld";
	($res) = $epp->register ($domain);
	is ($epp->get_code, 1000, "Domain registration under .$sld")
		or warn $epp->get_reason ();
}
for my $sld (qw/net.uk ltd.uk plc.uk/) {
	if ($sld eq 'plc.uk') {
		$registrant->{'type'}           = 'PLC';
		$domain->{registrant}           = $registrant;
		$domain->{registrant}->{'type'} = 'PLC';
		$domain->{registrant}->{id}     = "reg-$now-p";
	}
	$domain->{name} = "$now-b-$tag.$sld";
	($res) = $epp->register ($domain);
	is ($epp->get_code, 1001, "Domain registration under .$sld")
		or warn $epp->get_reason ();
}

$domain->{name} = "duncan-$tag.uk";
($res) = $epp->register ($domain);
is ($epp->get_code, 2201, ".uk domain registration attempt without rights")
	or warn $epp->get_reason ();


# Tests to register contacts #####
# Probably not really needed, but here for completeness ...
$registrant->{id} = "reg-b-$now";
$res = $epp->create_contact ($registrant);
is ($epp->get_code, 1000, 'Standalone contact creation');

delete $registrant->{id};
$res = $epp->create_contact ($registrant);
is ($epp->get_code, 1000,
	'Standalone contact creation with system-generated ID');

$registrant->{id} = "reg-c-$now";
#$registrant->{postalInfo}->{int} = $registrant->{postalInfo}->{loc};
#$registrant->{postalInfo}->{int}->{addr}->{city} = "Gondor";
$registrant->{'postalInfo'}->{int} = {
			'name'		=>	'Testy McTest',
			'org'		=>	'Acme Domain Company',
			'addr'		=>	{
				'street'	=>	['4 Rogazza Piazza'],
				'city'		=>	'Testington',
				'sp'		=>	'Testshire',
				'pc'		=>	'XL99 1XL',
				'cc'		=>	'GB'
			}
		},
delete $registrant->{'postalInfo'}->{loc};
$res = $epp->create_contact ($registrant);
is ($epp->get_code, 1000, 'Standalone contact creation with int and loc info');

# Tests to register nameservers #####
my $nameserver = {
	name	=>	"ns$now.foo.com",
	addrs	=>	[
		{ ip	=>	'99.199.99.199', version	=>	'v4' },
	],
};
$epp->create_host ($nameserver);
is ($epp->get_code, 1000, 'Nameserver registration under .com');

$epp->create_host ($nameserver);
is ($epp->get_code, 2302, 'Duplicate nameserver registration under .com');

$nameserver->{name} = "ns$now.banquo-$tag.co.uk";
$epp->create_host ($nameserver);
is ($epp->get_code, 1000, 'Nameserver registration under .uk');

$domain->{name} = "$now-c-$tag.co.uk";
$domain->{nameservers} = {
	nsname0	=>	"ns$now.foo.com",
	nsname1 =>	"ns$now.banquo-$tag.co.uk"
};
($res) = $epp->register ($domain);
is ($epp->get_code, 1000, 'Domain registration with just-created nameservers');

$domain->{name} = "$now-d-$tag.co.uk";
$domain->{nameservers} = {
	nsname0	=>	"ns$now.baz.com",
	nsname1 =>	"ns$now.jubber.slam.uk"
};
($res) = $epp->register ($domain);
isnt ($epp->get_code, 1000, 'Domain registration with non-existent nameservers');

$domain->{nameservers} = {};
($res) = $epp->register ($domain);
is ($epp->get_code, 1000, 'Domain registration with no nameservers') or
warn $epp->get_reason;

ok ($epp->logout(), 'Logout successful');

exit;

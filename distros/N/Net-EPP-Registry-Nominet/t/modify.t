#
#===============================================================================
#
#         FILE:  modify.t
#
#  DESCRIPTION:  Test of updates/modifications
#
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  28/03/13 14:58:33
#===============================================================================

use strict;
use warnings;
use utf8;

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 35;
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

# change nameservers on a domain

my $okdomainname  = "ganymede-$tag.net.uk"; # valid
my $baddomainname = "nominet.org.uk";       # not valid

my $changes = {
	'add' => { 'ns' => ["ns1.caliban-$tag.lea.sch.uk", "ns1.macduff-$tag.co.uk"] },
	'rem' => { 'ns' => ["ns1.ganymede-$tag.net.uk"] },
	'chg' => {}
};

ok ($epp->modify_domain ($okdomainname, $changes),
	"Change nameservers on domain");
my $info = $epp->domain_info ($okdomainname);
is ($info->{ns}->[0], "ns1.caliban-$tag.lea.sch.uk.", "Nameserver 0 changed");
is ($info->{ns}->[1], "ns1.macduff-$tag.co.uk.",      "Nameserver 1 changed");

$changes = {
	'add' => {},
	'rem' => {},
	'chg' => {},
	'auto-bill'  => 7,
	'auto-period'  => 5,
	'notes'      => ['This is the first note.', 'Here is another note.']
};

ok ($epp->modify_domain ($okdomainname, $changes),
	"Change extension fields on domain") or
	warn $epp->get_code . ' ' . $epp->get_reason;
$info = $epp->domain_info ($okdomainname);
is ($info->{'auto-bill'}, 7, "auto-bill changed");
is ($info->{'auto-period'}, 5, "auto-period changed");
is ($info->{notes}, join ("\n", @{$changes->{notes}}), "notes changed");

$epp->modify_domain ($baddomainname, $changes);
isnt ($epp->get_code, 1000, "Change extension fields on invalid domain");

# renew-not-required

$changes->{'auto-bill'} = undef;
$changes->{'auto-period'} = undef;
$changes->{'renew-not-required'} = 'y';
ok ($epp->modify_domain ($okdomainname, $changes),
	"Set renew-not-required") or
	warn $epp->get_code . ' ' . $epp->get_reason;
$info = $epp->domain_info ($okdomainname);
is ($info->{'renew-not-required'}, 'Y', 'Validated renew-not-required set');
$changes->{'renew-not-required'} = 'n';
ok ($epp->modify_domain ($okdomainname, $changes),
	"Unset renew-not-required") or
	warn $epp->get_code . ' ' . $epp->get_reason;
$info = $epp->domain_info ($okdomainname);
is ($info->{'renew-not-required'}, '', 'Validated renew-not-required unset');

# Change DS records for a domain

$changes = {
	'add'	=>	{
		'secDNS'	=>	[
			{
				keyTag     => 25102,
				alg	       => 5,
				digestType => 1,
				digest     => '7A9CEBB665B78E0142F1CEF47CC9F4205F600685'
			},
		]
	},
	'rem'	=>	{},
};

ok ($epp->modify_domain ($okdomainname, $changes),
	"Add DS record to domain");

$changes = {
	'rem'	=>	{
		'secDNS'	=>	[
			{
				keyTag     => 25102,
				alg	       => 5,
				digestType => 1,
				digest     => '7A9CEBB665B78E0142F1CEF47CC9F4205F600685'
			},
		]
	},
	'add'	=>	{
		'secDNS'	=>	[
			{
				keyTag     => 25103,
				alg	       => 5,
				digestType => 1,
				digest     => '8A9CEBB665B78E0142F1CEF47CC9F4205F600685'
			},
		]
	},
};

ok ($epp->modify_domain ($okdomainname, $changes),
	"Replace DS record for domain");

$changes = {
	'rem'	=>	{
		'secDNS'	=>	[
			{
				keyTag     => 25103,
				alg	       => 5,
				digestType => 1,
				digest     => '8A9CEBB665B78E0142F1CEF47CC9F4205F600685'
			},
		]
	},
	'add'	=>	{},
};

ok ($epp->modify_domain ($okdomainname, $changes),
	"Remove DS record from domain");

# change details of a registrant
my $cont = {
	'type'		=>	'FCORP',
	'trad-name'	=>	'American Industries',
	'co-no'		=>	'99998888'
};

my $dominfo = $epp->domain_info ("duncan-$tag.co.uk");

ok ($epp->modify_contact ($dominfo->{registrant}, $cont),
	"Modify contact extras");

# change details of a contact (much the same as reg)
$cont = {
	postalInfo => { loc => {
		name	=>	'Bob "the Shred" Banker',
		addr	=>	{
			street	=>	['Bank Towers', '10 Big Bank Street'],
			city	=>	'London',
			sp		=>	'',
			pc		=>	'BB1 1XL',
			cc		=>	'GB'
		},
	}},
	voice	=>	'+44.7777777666',
	email	=>	'bankerbob@example.com'
};

ok ($epp->modify_contact ($dominfo->{registrant}, $cont),
	"Modify contact name/addr/phone/email");

# Change some details with UTF-8 chars

$cont->{postalInfo}->{loc}->{addr} = {
	street	=>	['75 Rue de la Mer'],
	city	=>	'Saint-André-de-Bâgé',
	sp	=>	'Ain',
	pc 	=>	'01332',
	cc	=>	'FR'
};
ok ($epp->modify_contact ($dominfo->{registrant}, $cont),
	"Modify utf8 contact");

# Change disclosure levels for a contact
# Create a new contact for this first
$cont = {
	type    => 'IND',
	postalInfo => { loc => {
		name    =>  'Zaphod Beeblebox',
		org     =>  'Zaphod Beeblebox',
		addr    =>  {
			street  =>  ['Presidential Plaza'],
			city    =>  'London',
			sp      =>  '',
			pc      =>  'ZB1 1XL',
			cc      =>  'GB'
		},
	}},
	voice   =>  '+44.1717778888',
	email   =>  '2heads@example.com'
};
$epp->create_contact ($cont);
my $cid = $cont->{id};
$cont = {disclose => {addr => 1}};
ok ($epp->modify_contact ($cid, $cont),
	"Modify address disclosure for contact");
my $res = $epp->contact_info ($cid);
ok ($res->{disclose}->{addr}, 'Address disclosed');
ok (!$res->{disclose}->{org}, 'Org not disclosed');
$cont->{disclose} = {addr => 0, org => 1};
is ($epp->modify_contact ($cid, $cont), undef,
	"Error modifying both disclosures to different values");
$cont->{disclose} = {org => 1};
ok ($epp->modify_contact ($cid, $cont),
	"Modify org disclosure for contact");
$res = $epp->contact_info ($cid);
ok ($res->{disclose}->{addr}, 'Address disclosed');
ok ($res->{disclose}->{org}, 'Org disclosed');
$cont->{disclose} = {addr => 1, org => 1};
ok ($epp->modify_contact ($cid, $cont),
	"Modify both disclosures to true for contact");
$res = $epp->contact_info ($cid);
ok ($res->{disclose}->{addr}, 'Address disclosed');
ok ($res->{disclose}->{org}, 'Org disclosed');
$cont->{disclose} = {addr => 0, org => 0};
ok ($epp->modify_contact ($cid, $cont),
	"Modify both disclosures to false for contact");
$res = $epp->contact_info ($cid);
ok (!$res->{disclose}->{addr}, 'Address not disclosed');
ok (!$res->{disclose}->{org}, 'Org not disclosed');

# change details of a nameserver
# Get the current IPv6 address first
my $ns = "ns1.benedick-$tag.co.uk";
$info = $epp->host_info ($ns);
my $oldv6 = '';
for my $addr (@{$info->{addrs}}) {
	if ($addr->{version} and $addr->{version} eq 'v6') { $oldv6 = $addr->{addr}; last; }
}
if ($oldv6) {
	my $newv6 = $oldv6;
	$newv6 =~ s/(\d)$/($1+1)%2/e;
	$changes = {
		'rem' => { 'addr' => [ { ip => $oldv6, version => "v6" } ] },
		'add' => { 'addr' => [ { ip => $newv6, version => "v6" } ] },
	};
} else {
	$changes = {
		'add' => { 'addr' => [ { ip => "1080:0:0:0:8:800:200C:4170", version => "v6" } ] },
	};
}

ok ($epp->modify_host ($ns, $changes), "Modify nameserver")
or warn $epp->get_reason;

ok ($epp->logout(), 'Logout');

exit;

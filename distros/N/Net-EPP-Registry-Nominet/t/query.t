#
#===============================================================================
#
#         FILE:  query.t
#
#  DESCRIPTION:  Query domain info
#
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  04/02/13 15:01:59
#===============================================================================

use strict;
use warnings;
use utf8;

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 28;
} else {
	plan skip_all => 'Cannot connect to testbed without NOMTAG and NOMPASS';
}

use Net::EPP::Registry::Nominet;

my $epp = new_ok ('Net::EPP::Registry::Nominet', [ ote => 1,
	user => $ENV{NOMTAG}, pass => $ENV{NOMPASS}, debug =>
	$ENV{DEBUG_TEST} || 0 ] );

my $tag = lc $ENV{NOMTAG};

# Prepare

my $changes = {
	'add' => { 'ns' => ["ns1.oberon-$tag.co.uk", "ns1.macduff-$tag.co.uk"] },
	'rem' => {},
	'chg' => {}
};

$epp->modify_domain ("duncan-$tag.co.uk", $changes);

# Domains
my $info = $epp->domain_info ("duncan-$tag.co.uk");

like ($info->{exDate}, qr/^\d\d\d\d-/, 'Correct domain info');
my $reg = $info->{registrant};
my $ns  = $info->{ns};

$info = $epp->domain_info ("duncan-$tag.co.uk", undef, 1);

like ($info->{exDate}, qr/^\d\d\d\d-/, 'Correct domain info with follow');

$info = $epp->domain_info ("ophelia-$tag.co.uk");
like ($info->{exDate}, qr/^\d\d\d\d-/, 'Correct domain info with DNSSEC');
ok (exists $info->{secDNS}, 'Have secDNS element');
is (ref ($info->{secDNS}), 'ARRAY', 'It is an array ref');
cmp_ok ($#{$info->{secDNS}}, '>', '-1', 'The array is not empty');
my $ds = $info->{secDNS}->[0]; # for brevity
is ($ds->{digestType}, 1, 'DS digest type matched');
is ($ds->{alg}, 5, 'DS algorithm matched');
is ($ds->{keyTag}, 12345, 'DS key tag matched');
like ($ds->{digest}, qr/^[0-9A-F]{40}$/, 'DS digest has expected format');

# Contacts
$info = $epp->contact_info ($reg);
like ($info->{crDate}, qr/^\d\d\d\d-/, 'Contact info retrieved');
is ($info->{'type'}, 'FCORP', 'Registrant type matches');
is ($info->{'trad-name'}, 'American Industries', 'Registrant trad-name matches');
is ($info->{'co-no'}, '99998888', 'Registrant company number matches');
is ($info->{'voice'}, '+44.7777777666', 'Contact voice matches');
is ($info->{'email'}, 'bankerbob@example.com', 'Contact email matches');
my $loc = $info->{'postalInfo'}->{'loc'};
is ($loc->{'name'}, 'Bob "the Shred" Banker', 'Contact name matches');
is ($loc->{'org'}, "Suspensions Registrant-$ENV{NOMTAG}",
	'Contact org matches');
my $addr = $loc->{'addr'};
is ($addr->{'street'}->[0], '75 Rue de la Mer', 'Contact street matches');
is ($addr->{'city'}, 'Saint-André-de-Bâgé', 'Contact city matches');
is ($addr->{'sp'}, 'Ain', 'Contact state matches');
is ($addr->{'pc'}, '01332', 'Contact postcode matches');
is ($addr->{'cc'}, 'FR', 'Contact country code matches');
is ($info->{'disclose'}->{addr}, undef, 'Disclose addr matches');
is ($info->{'disclose'}->{org},  undef, 'Disclose org matches');


# Hosts
$info = $epp->host_info ($ns->[0]);
is ($info->{clID}, $ENV{NOMTAG}, 'Correct host info');

ok ($epp->logout(), 'Logout successful');

exit;

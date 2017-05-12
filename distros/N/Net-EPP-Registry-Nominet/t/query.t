#
#===============================================================================
#
#         FILE:  query.t
#
#  DESCRIPTION:  Query domain info
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      VERSION:  $Id: query.t,v 1.3 2015/08/21 16:10:41 pete Exp $
#      CREATED:  04/02/13 15:01:59
#     REVISION:  $Revision: 1.3 $
#===============================================================================

use strict;
use warnings;
use utf8;

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 20;
} else {
	plan skip_all => 'Cannot connect to testbed without NOMTAG and NOMPASS';
}

use lib './lib';
use Net::EPP::Registry::Nominet;

my $epp = new_ok ('Net::EPP::Registry::Nominet', [ test => 1,
	user => $ENV{NOMTAG}, pass => $ENV{NOMPASS}, debug =>
	$ENV{DEBUG_TEST} || 0 ] );

my $tag = lc $ENV{NOMTAG};

# Domains
my $info = $epp->domain_info ("duncan-$tag.co.uk");

like ($info->{exDate}, qr/^\d\d\d\d-/, 'Correct domain info');
my $reg = $info->{registrant};
my $ns  = $info->{ns};

$info = $epp->domain_info ("duncan-$tag.co.uk", undef, 1);

like ($info->{exDate}, qr/^\d\d\d\d-/, 'Correct domain info with follow');

$info = $epp->domain_info ("ophelia-$tag.co.uk");
like ($info->{exDate}, qr/^\d\d\d\d-/, 'Correct domain info with DNSSEC');

# Contacts
$info = $epp->contact_info ($reg);
like ($info->{crDate}, qr/^\d\d\d\d-/, 'Contact info retrieved');
is ($info->{'type'}, 'FCORP', 'Registrant type matches');
is ($info->{'trad-name'}, 'American Industries', 'Registrant trad-name matches');
is ($info->{'co-no'}, '99998888', 'Registrant company number matches');
is ($info->{'opt-out'}, 'N', 'Registrant opt-out matches');
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


# Hosts
$info = $epp->host_info ($ns->[0]);
is ($info->{clID}, $ENV{NOMTAG}, 'Correct host info');

ok ($epp->logout(), 'Logout successful');

exit;

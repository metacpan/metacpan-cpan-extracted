#
#===============================================================================
#
#         FILE: 0-ote-check.t
#
#  DESCRIPTION: Check all the OT&E testbed domains are present
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 11/07/19 14:09:43
#===============================================================================

use strict;
use warnings;

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 44;
} else {
	plan skip_all => 'Cannot connect without NOMTAG and NOMPASS';
}

use Net::EPP::Registry::Nominet;

my $epp = new_ok ('Net::EPP::Registry::Nominet', [ ote => 1,
	user => $ENV{NOMTAG}, pass => $ENV{NOMPASS},
	debug => $ENV{DEBUG_TEST} || 0] );

is ($Net::EPP::Registry::Nominet::Code, 1000, 'Logged in');

diag $Net::EPP::Registry::Nominet::Error if
$Net::EPP::Registry::Nominet::Error;

BAIL_OUT ("Cannot login to EPP server") if
		$Net::EPP::Registry::Nominet::Error;

my $tag     = lc $ENV{NOMTAG};
my $res     = undef;
my $abuse   = undef;
my $rights  = undef;
my @doms = (
	"adriana-$tag.co.uk",
	"banquo-$tag.co.uk",
	"beatrice-$tag.co.uk",
	"caliban-$tag.lea.sch.uk",
	"claudio-$tag.lea.sch.uk",
	"demetrius-$tag.co.uk",
	"duncan-$tag.co.uk",
	"ganymede-$tag.net.uk",
	"ganymede-$tag.co.uk",
	"ganymede-$tag.plc.uk",
	"hermione-$tag.co.uk",
	"hermia-$tag.plc.uk",
	"horatio-$tag.co.uk",
	"juliet-$tag.plc.uk",
	"lysander-$tag.co.uk",
	"macbeth-$tag.plc.uk",
	"perdita-$tag.co.uk",
	"perdita-$tag.org.uk",
	"macduff-$tag.co.uk",
	"mercutio-$tag.co.uk",
	"oberon-$tag.co.uk",
	"oberon-$tag.org.uk",
	"ophelia-$tag.co.uk",
	"portia-$tag.co.uk",
	"romeo-$tag.co.uk",
	"titania-$tag.co.uk",
	"aegeon-$tag.co.uk"
);

# Check domains
for my $dom (@doms) {
	($res, $abuse) = $epp->check_domain ($dom);
	is ($res, 0, "Existent domain check: $dom");
}

my @hosts = (
	"ns1.benedick-$tag.co.uk",
	"ns1.ariel-$tag.co.uk",
	"ns1.beatrice-$tag.co.uk",
	"ns2.beatrice-$tag.co.uk",
	"ns1.caliban-$tag.lea.sch.uk",
	"ns1.demetrius-$tag.co.uk",
	"ns1.ganymede-$tag.net.uk",
	"ns1.macduff-$tag.co.uk",
	"ns1.oberon-$tag.co.uk",
	"ns1.ophelia-$tag.co.uk",
	"ns1.portia-$tag.co.uk",
	"ns1.romeo-$tag.co.uk",
	"ns1.titania-$tag.co.uk",
	"ns1.aegeon-$tag.co.uk"
);

for my $host (@hosts) {
	($res) = $epp->check_host ($host);
	is ($res, 0, "Existent host check: $host");
}

ok ($epp->logout(), 'Logout');

exit;


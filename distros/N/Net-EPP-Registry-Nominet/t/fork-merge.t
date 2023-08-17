#
#===============================================================================
#
#         FILE: fork-merge.t
#
#  DESCRIPTION: Test of forking and merging contacts
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 20/02/23 10:41:03
#===============================================================================

use strict;
use warnings FATAL => 'recursion';

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 8;
} else {
	plan skip_all => 'Cannot connect to testbed without NOMTAG and NOMPASS';
}

use Net::EPP::Registry::Nominet;

my $epp = new_ok (
	'Net::EPP::Registry::Nominet',
	[   ote   => 1,
		user  => $ENV{NOMTAG},
		pass  => $ENV{NOMPASS},
		debug => $ENV{DEBUG_TEST} || 0
	]
);

is ($Net::EPP::Registry::Nominet::Code, 1000, 'Logged in');

if ($Net::EPP::Registry::Nominet::Error) {
	warn $Net::EPP::Registry::Nominet::Error;
	BAIL_OUT ("Cannot login to EPP server");
}

my $tag = lc $ENV{NOMTAG};

# fork
my $forkdom = "beatrice-$tag.co.uk";
my $staydom = "banquo-$tag.co.uk";
my $oldid   = regidfromdom ($staydom);
my $newid   = substr ('mr' . time . $tag, 0, 16);
my $res     = $epp->fork ($oldid, $newid, $forkdom);
is $res, $newid, "Contact forked with provided new ID $newid";

# Check the domains
is regidfromdom ($forkdom), $newid, "$forkdom forked";
is regidfromdom ($staydom), $oldid, "$staydom retained";

# merge back domain
$res = $epp->modify_domain ($forkdom, {chg => {registrant => $oldid}});
is $res,                    1,      "Re-merged into $oldid";
is regidfromdom ($forkdom), $oldid, "$forkdom re-merged";

ok ($epp->logout (), 'Logout');

exit;

sub regidfromdom {
	my $info = $epp->domain_info (shift);
	return $info->{registrant};
}

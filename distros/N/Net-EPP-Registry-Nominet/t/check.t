#
#===============================================================================
#
#         FILE:  check.t
#
#  DESCRIPTION:  Test of EPP Check command
#
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  04/02/13 17:15:33
#===============================================================================

use strict;
use warnings;

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 16;
} else {
	plan skip_all => 'Cannot connect to testbed without NOMTAG and NOMPASS';
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
my $reason  = undef;

# Check domains
($res, $abuse, $reason) = $epp->check_domain ("duncan-$tag.co.uk");
is ($res, 0, 'Existent domain check');
like ($abuse, qr/^[0-9]+$/, 'Existent domain check abuse counter');
my $abuseval = $abuse;
diag "Abuse = $abuse\n" if $ENV{DEBUG_TEST};
is ($reason, 'Registered', 'Reason is "Registered"');

($res, $abuse, $reason) = $epp->check_domain ("octavia-$tag.co.uk");
is ($res, 0, 'Existent pending delete domain check');
is ($abuse, --$abuseval, 'Existent pending delete domain check abuse counter');
diag "Abuse = $abuse\n" if $ENV{DEBUG_TEST};
like ($reason, qr/^drop \d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/,
	'Reason is "drop <ISO drop time>"');
diag "Reason = $reason\n" if $ENV{DEBUG_TEST};

($res, $abuse, $reason) = $epp->check_domain ("dlfkgshklghsld-$tag.co.uk");
is ($res, 1, 'Non-existent domain check');
is ($abuse, --$abuseval, 'Non-existent domain check abuse counter');
diag "Abuse = $abuse\n" if $ENV{DEBUG_TEST};
is ($reason, undef, 'Reason is undef');

# Check contacts
# First get a valid contact ID, since they change in the testbed between
# reloads
($res, $abuse) = $epp->check_contact ($epp->domain_info ("adriana-$tag.co.uk")->{registrant});
is ($res, 0, 'Existent contact check');
($res, $abuse) = $epp->check_contact ("thiswillfail");
is ($res, 1, 'Non-existent contact check');

# Here would go validity checks once the draft at
# https://www.ietf.org/archive/id/draft-ietf-regext-validate-03.txt
# has made it to full RFC.
#($res, $abuse) = $epp->check_valid_contact ($contact);
#is_deeply ($res, [1], 'Valid contact');

# Check hosts
($res, $abuse) = $epp->check_host ("ns1.oberon-$tag.co.uk");
is ($res, 0, 'Existent host check');
($res, $abuse) = $epp->check_host ("nothere.oberon-$tag.co.uk");
is ($res, 1, 'Non-existent host check');

ok ($epp->logout(), 'Logout');

exit;

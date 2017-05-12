#
#===============================================================================
#
#         FILE:  check.t
#
#  DESCRIPTION:  Test of EPP Check command
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      VERSION:  $Id: check.t,v 1.4 2015/10/02 10:22:45 pete Exp $
#      CREATED:  04/02/13 17:15:33
#     REVISION:  $Revision: 1.4 $
#===============================================================================

use strict;
use warnings;

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 17;
} else {
	plan skip_all => 'Cannot connect to testbed without NOMTAG and NOMPASS';
}

use lib './lib';
use Net::EPP::Registry::Nominet;

my $epp = new_ok ('Net::EPP::Registry::Nominet', [ test => 1,
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

# Check domains
($res, $abuse) = $epp->check_domain ("duncan-$tag.co.uk");
is ($res, 0, 'Existent domain check');
like ($abuse, qr/^[0-9]+$/, 'Existent domain check abuse counter');
my $abuseval = $abuse;
diag "Abuse = $abuse\n" if $ENV{DEBUG_TEST};
($res, $abuse) = $epp->check_domain ("dlfkgshklghsld-$tag.co.uk");
is ($res, 1, 'Non-existent domain check');
is ($abuse, --$abuseval, 'Non-existent domain check abuse counter');
diag "Abuse = $abuse\n" if $ENV{DEBUG_TEST};
($res, $abuse, $rights) = $epp->check_domain ("dlfkgshklghsld-$tag.uk");
is ($res, 1, 'Non-existent .uk domain check');
is ($abuse, --$abuseval, 'Non-existent .uk domain check abuse counter');
is ($rights, undef, 'Non-existent .uk domain rights check without rights');
diag "Abuse = $abuse\n" if $ENV{DEBUG_TEST};
($res, $abuse, $rights) = $epp->check_domain ("duncan-$tag.uk");
is ($res, 1, 'Non-existent .uk domain check with rights');
is ($abuse, --$abuseval, 'Non-existent .uk domain check with rights abuse counter');
is ($rights, "duncan-$tag.co.uk", 'Non-existent .uk domain rights check with rights');
diag "Abuse = $abuse\n" if $ENV{DEBUG_TEST};


# Check contacts
# First get a valid contact ID, since they change in the testbed between
# reloads
($res, $abuse) = $epp->check_contact ($epp->domain_info ("adriana-$tag.co.uk")->{registrant});
is ($res, 0, 'Existent contact check');
($res, $abuse) = $epp->check_contact ("thiswillfail");
is ($res, 1, 'Non-existent contact check');

# Check hosts
($res, $abuse) = $epp->check_host ("ns1.oberon-$tag.co.uk");
is ($res, 0, 'Existent host check');
($res, $abuse) = $epp->check_host ("nothere.oberon-$tag.co.uk");
is ($res, 1, 'Non-existent host check');

ok ($epp->logout(), 'Logout');

exit;

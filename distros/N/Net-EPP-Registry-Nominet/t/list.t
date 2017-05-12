#
#===============================================================================
#
#         FILE:  list.t
#
#  DESCRIPTION:  Test the list operation
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  Must have set $NOMTAG and $NOMPASS env vars first
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      VERSION:  $Id: list.t,v 1.1.1.1 2013/10/21 14:04:54 pete Exp $
#      CREATED:  04/02/13 13:22:06
#     REVISION:  $Revision: 1.1.1.1 $
#===============================================================================

use strict;
use warnings;

use Test::More;

if (defined $ENV{NOMTAG} and defined $ENV{NOMPASS}) {
	plan tests => 5;
} else {
	plan skip_all => 'Cannot connect to testbed without NOMTAG and NOMPASS';
}

use lib './lib';
use Net::EPP::Registry::Nominet;

my $epp = new_ok ('Net::EPP::Registry::Nominet', [ test => 1,
	user => $ENV{NOMTAG}, pass => $ENV{NOMPASS}, debug =>
	$ENV{DEBUG_TEST} || 0 ] );

my $range = '2000-01';
my $domlist = $epp->list_domains ($range);

is (@$domlist, 0, 'Correct empty domain expiry list');

my @lt = localtime (time ());
$range = sprintf ('%4.4i-%2.2i', $lt[5] + 1900, $lt[4] + 1);
$domlist = $epp->list_domains ($range);
isnt (@$domlist, 0, "Correct domain list for $range");

# Now try with registration date
$range = sprintf ('%4.4i-%2.2i', $lt[5] + 1898, $lt[4] + 1);
$domlist = $epp->list_domains ($range, 'month');
isnt (@$domlist, 0, "Correct domain list for $range");

ok ($epp->logout(), 'Logout successful');

exit;

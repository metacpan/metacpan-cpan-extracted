######################################################################
# Test suite for SWISH::API::Common
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
use Sysadm::Install qw(:all);
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

BEGIN { use_ok('SWISH::API::Common') };

my $CANNED = "eg/canned";
$CANNED = "../eg/canned" unless -d $CANNED;

use SWISH::API::Common;

    # Preserving atime
my $sw = SWISH::API::Common->new(swish_adm_dir  => "$CANNED/adm",
                              atime_preserve => 1);

my ($atime, $mtime) = (stat("$CANNED/data1/abc"))[8,9];
die "Cannot get atime" unless $atime;

sleep(1);
$sw->index("$CANNED/data1/abc");

my ($atime2, $mtime2) = (stat("$CANNED/data1/abc"))[8,9];

ok($atime <= $atime2, "atime unmodified by index");
ok($mtime <= $mtime2, "mtime unmodified by index");

END { rmf "$CANNED/adm"; }

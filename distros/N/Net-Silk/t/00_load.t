use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 12;

BEGIN { use_ok('Net::Silk') }

use Net::Silk qw( :basic );

use_ok(SILK_IPADDR_CLASS);
use_ok(SILK_BAG_CLASS);
use_ok(SILK_FILE_CLASS);
use_ok(SILK_IPADDR_CLASS);
use_ok(SILK_IPSET_CLASS);
use_ok(SILK_IPWILDCARD_CLASS);
use_ok(SILK_PMAP_CLASS);
use_ok(SILK_PROTOPORT_CLASS);
use_ok(SILK_RWREC_CLASS);
use_ok(SILK_SITE_CLASS);
use_ok(SILK_TCPFLAGS_CLASS);

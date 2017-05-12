use Test;
BEGIN { plan(tests => 1) }

use Net::Frame::Dump qw(:consts);
use Net::Frame::Dump::Online;
use Net::Frame::Dump::Online2;
use Net::Frame::Dump::Offline;
use Net::Frame::Dump::Writer;

ok(1);

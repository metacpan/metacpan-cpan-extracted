use Test::More tests => 5;

BEGIN { use_ok('Net::WDNS') }

use_ok("Net::WDNS::RD");
use_ok("Net::WDNS::RR");
use_ok("Net::WDNS::Question");
use_ok("Net::WDNS::Msg");

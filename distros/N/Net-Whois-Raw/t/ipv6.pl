use strict;
use warnings;

use Test::RequiresInternet;
use Test::More tests => 2;

use_ok 'Net::Whois::Raw';

# this test requires ipv6 connection
like eval{ whois( '2606:2800:220:1:248:1893:25c8:1946', '2001:500:31::46' ) }, qr/ARIN/, 'ipv6 connection to whois server';

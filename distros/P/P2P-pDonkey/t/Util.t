#########################

use Test;
BEGIN { plan tests => 1 };

use P2P::pDonkey::Util ':all';

#########################

ok(ip2addr(addr2ip('176.16.4.244')) eq '176.16.4.244');


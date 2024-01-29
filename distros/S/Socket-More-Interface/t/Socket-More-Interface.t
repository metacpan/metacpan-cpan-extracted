use strict;
use warnings;

use Test::More; 
BEGIN { use_ok('Socket::More::Interface') };


use Socket::More::Interface;
{
	#Do we get any interfaces at all?
	my @interfaces=getifaddrs;
	ok @interfaces>=1, "interfaces returned";
}

done_testing;

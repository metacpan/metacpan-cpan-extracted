use Test::More tests => 1;
BEGIN { use_ok('Net::DNS::Nslookup') };

use strict;
use Net::DNS::Nslookup;

my $dns_resp = Net::DNS::Nslookup->get_ips("www.google.com");
printf("%s\n", $dns_resp);

exit(0);

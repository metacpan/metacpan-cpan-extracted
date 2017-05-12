use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }
use Net::Whois::Proxy;
$loaded++;

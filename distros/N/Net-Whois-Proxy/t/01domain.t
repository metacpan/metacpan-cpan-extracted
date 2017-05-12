use strict;
use Test;
BEGIN { plan tests => 2 }
use Net::Whois::Proxy;

my $wp = new Net::Whois::Proxy;

ok($wp);
ok($wp->whois("fpsn.net") =~ /FPSN/i ? 1 : 0, 1);

use strict;
use warnings;

use Test::More;

use lib '.';
use t::test;

plan skip_all => "Not running as root; skipping ICMPv6 raw socket pings" if $>;

t::test::run_tests('icmpv6', {
    unreachable => '100::1',
    reserved    => '2001:db8::1',
});

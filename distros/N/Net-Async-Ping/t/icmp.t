use strict;
use warnings;

use Test::More;

use lib '.';
use t::test;

plan skip_all => "Not running as root; skipping ICMP raw socket pings" if $>;

t::test::run_tests('icmp', {
    unreachable => '192.168.0.197',
    reserved    => '192.0.2.0',
});

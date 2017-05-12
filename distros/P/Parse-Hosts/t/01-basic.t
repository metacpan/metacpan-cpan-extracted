#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Parse::Hosts qw(parse_hosts);

my $content = <<'_';
127.0.0.1	localhost
127.0.1.1	foo.bar

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

_

is_deeply(
    parse_hosts(content => $content),
    [200, "OK", [
        {ip => '127.0.0.1', hosts => ['localhost']},
        {ip => '127.0.1.1', hosts => ['foo.bar']},
        {ip => '::1', hosts => ['ip6-localhost', 'ip6-loopback']},
        {ip => 'fe00::0', hosts => ['ip6-localnet']},
        {ip => 'ff00::0', hosts => ['ip6-mcastprefix']},
        {ip => 'ff02::1', hosts => ['ip6-allnodes']},
        {ip => 'ff02::2', hosts => ['ip6-allrouters']},
    ]]
);

done_testing;

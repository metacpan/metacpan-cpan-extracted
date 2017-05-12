use Template::Test;
use Template::Plugin::IPAddr;

# Set this to true to see each test running
$Template::Test::DEBUG = 1;

my $config = {
  PLUGINS => {
    IPAddr => 'Template::Plugin::IPAddr',
  }
};

test_expect(\*DATA, $config);

__DATA__
-- test --
[% USE IPAddr -%]
addr: [% IPAddr.addr %]
addr_cidr: [% IPAddr.addr_cidr %]
cidr: [% IPAddr.cidr %]
first: [% IPAddr.first %]
last: [% IPAddr.last %]
network: [% IPAddr.network %]
netmask: [% IPAddr.netmask %]
wildcard: [% IPAddr.wildcard %]
-- expect --
addr: 0.0.0.0
addr_cidr: 0.0.0.0/0
cidr: 0.0.0.0/0
first: 0.0.0.1
last: 255.255.255.254
network: 0.0.0.0
netmask: 0.0.0.0
wildcard: 255.255.255.255

-- test --
[% USE IPAddr('172.16.0.0/16') -%]
addr: [% IPAddr.addr %]
addr_cidr: [% IPAddr.addr_cidr %]
cidr: [% IPAddr.cidr %]
first: [% IPAddr.first %]
last: [% IPAddr.last %]
network: [% IPAddr.network %]
netmask: [% IPAddr.netmask %]
wildcard: [% IPAddr.wildcard %]
-- expect --
addr: 172.16.0.0
addr_cidr: 172.16.0.0/16
cidr: 172.16.0.0/16
first: 172.16.0.1
last: 172.16.255.254
network: 172.16.0.0
netmask: 255.255.0.0
wildcard: 0.0.255.255

-- test --
[% USE IPAddr -%]
[% ip = IPAddr.new('10.0.0.100/24') -%]
addr: [% ip.addr %]
addr_cidr: [% ip.addr_cidr %]
cidr: [% ip.cidr %]
first: [% ip.first %]
last: [% ip.last %]
network: [% ip.network %]
netmask: [% ip.netmask %]
wildcard: [% ip.wildcard %]
-- expect --
addr: 10.0.0.100
addr_cidr: 10.0.0.100/24
cidr: 10.0.0.0/24
first: 10.0.0.1
last: 10.0.0.254
network: 10.0.0.0
netmask: 255.255.255.0
wildcard: 0.0.0.255

-- test --
[% USE IPAddr -%]
[% ip = IPAddr.new('192.0.2.1') -%]
addr: [% ip.addr %]
addr_cidr: [% ip.addr_cidr %]
cidr: [% ip.cidr %]
first: [% ip.first %]
last: [% ip.last %]
-- expect --
addr: 192.0.2.1
addr_cidr: 192.0.2.1/32
cidr: 192.0.2.1/32
first: 192.0.2.1
last: 192.0.2.1

-- test --
[% USE IPAddr('2001:db8:1234:5678::abcd/64') -%]
addr: [% IPAddr.addr %]
addr_cidr: [% IPAddr.addr_cidr %]
cidr: [% IPAddr.cidr %]
first: [% IPAddr.first %]
last: [% IPAddr.last %]
network: [% IPAddr.network %]
-- expect --
addr: 2001:db8:1234:5678::abcd
addr_cidr: 2001:db8:1234:5678::abcd/64
cidr: 2001:db8:1234:5678::/64
first: 2001:db8:1234:5678::1
last: 2001:db8:1234:5678:ffff:ffff:ffff:fffe
network: 2001:db8:1234:5678::

-- test --
[% USE IPAddr('::192.0.2.1') -%]
addr: [% IPAddr.addr %]
-- expect --
addr: ::c000:201

-- test --
[% USE IPAddr('2001:db8:a:b:c:d:e:f/48') -%]
addr: [% IPAddr.addr %]
addr_cidr: [% IPAddr.addr_cidr %]
cidr: [% IPAddr.cidr %]
first: [% IPAddr.first %]
last: [% IPAddr.last %]
network: [% IPAddr.network %]
-- expect --
addr: 2001:db8:a:b:c:d:e:f
addr_cidr: 2001:db8:a:b:c:d:e:f/48
cidr: 2001:db8:a::/48
first: 2001:db8:a::1
last: 2001:db8:a:ffff:ffff:ffff:ffff:fffe
network: 2001:db8:a::


#!perl

use warnings;
use strict;
use lib q(lib);
use Net::ISC::DHCPd::Config;
use Benchmark;
use NetAddr::IP;
use Test::More;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
$config->parse;
is(scalar $config->remove_functions( { name => 'update' } ), 0, 'Removed zero on update functions');
is(scalar $config->remove_hosts( { name => 'foo2' } ), 1, 'remove host foo2');
is(scalar $config->remove_hosts( { name => 'foo' } ), 1, 'remove host foo');
is(scalar $config->remove_subnets( { address => '10.0.0.96/27' } ), 1, 'removing subnet');
is(scalar $config->remove_keyvalues( { name => 'ddns-update-style' } ), 1, 'removing ddns-update-style');
is(scalar $config->remove_functions( { name => 'commit' } ), 2, 'Removed 2 on commit functions');
is(scalar $config->remove_optionspaces( { name => 'foo' } ), 1, 'Removed optionspace');
is(scalar $config->remove_keyvalues( { name => 'domain-name-servers' } ), 1, 'removed option domain-name-servers');
is(scalar $config->remove_optioncodes( {} ), 2, 'Removed all (2) optioncodes');
is($config->generate, "\n", 'Config is empty');
done_testing();

__DATA__
ddns-update-style none;
option space foo;
option foo.bar code 1 = ip-address;
option foo-enc code 122 = encapsulate foo;
on commit {
    set leasetime = encode-int(lease-time, 32);
}
domain-name-servers 192.168.1.5;
host foo {
    filename pxelinux.0;
    fixed-address 10.19.83.102;
}

subnet 10.0.0.96 netmask 255.255.255.224 {
    filename pxefoo.0;
    option routers 10.0.0.97;
    pool {
        range 10.0.0.126 10.0.0.116;
    }
}
on commit {
    set leasetime = encode-int(lease-time, 32);
}
host foo2 {
    filename pxelinux.0;
    fixed-address 10.19.83.102;
}

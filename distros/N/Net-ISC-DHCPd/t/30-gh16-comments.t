# consider merging this with braces.t

use lib './lib';
use Net::ISC::DHCPd::Config;
use Test::More;
use warnings;
use strict;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
is($config->parse, 8, 'Parsed 8 lines?');

done_testing();

__DATA__
subnet 10.1.10.0 netmask 255.255.255.0 {
option broadcast-address 10.1.10.255;
option routers 10.1.10.1;
option subnet-mask 255.255.255.0; # parsing this comment fails blaming the next lines
option domain-name-servers 10.1.10.11, 10.1.10.12;
if substring (option vendor-class-identifier,0,9) = "PXEClient" {
filename "pxelinux.0";
}

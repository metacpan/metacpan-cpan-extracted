#!/usr/bin/env perl

use warnings;
use strict;

use Net::IP::XS qw($IP_NO_OVERLAP $IP_PARTIAL_OVERLAP
                   $IP_A_IN_B_OVERLAP $IP_B_IN_A_OVERLAP
                   $IP_IDENTICAL);
use IO::Capture::Stderr;
my $c = IO::Capture::Stderr->new();

use Test::More tests => 154;
use Scalar::Util qw(blessed);

my $ip = Net::IP::XS->new('1.2.3.4', 4);
ok((blessed $ip and $ip->isa('Net::IP::XS')),
    'IP object is blessed and has correct package');
# Make sure that deleting the unsigned ints storing the start
# and end addresses doesn't cause segfaults.
delete $ip->{'xs_v4_ip0'};
delete $ip->{'xs_v4_ip1'};
my $res = $ip->size();

$ip = Net::IP::XS->new('1.2.3.4', 4);
ok((blessed $ip and $ip->isa('Net::IP::XS')),
    'IP object is blessed and has correct package');

$ip = Net::IP::XS->new('ZXCV', 4);
ok((not $ip), 'Got no object on bad arguments');

$ip = Net::IP::XS->new('2.0.0.0 - 1.0.0.0', 4);
ok((not $ip), 'Got no object where start address is more than end address');
is($Net::IP::XS::ERROR, 'Begin address is greater than End address 2.0.0.0 - 1.0.0.0', 'Correct error');
is($Net::IP::XS::ERRNO, 202, 'Correct errno');

$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
ok((blessed $ip and $ip->isa('Net::IP::XS')),
    'IP object is blessed and has correct package');
is($ip->intip(), 16777216, 'Got correct intip for IPv4 range');
is($ip->binip(), '00000001000000000000000000000000',
    'binip is correct');
is($ip->prefixlen(), 8, 'prefixlen is correct');
ok($ip->is_prefix(), 'is_prefix is correct');
is($ip->ip(), '1.0.0.0', 'ip is correct');
is($ip->version(), 4, 'ipversion is correct');
is($ip->binmask(), '11111111000000000000000000000000', 'binmask is correct');
is($ip->last_bin(), '00000001111111111111111111111111', 'last_bin is correct');
is($ip->print(), '1/8', 'Got correct printed value');
is($ip->size(), 16777216, 'Got correct size');
is($ip->intip(), '16777216', 'Got correct intip for IPv4 range');
is($ip->hexip(), '0x1000000', 'Got correct hexip for IPv4 range');
is($ip->hexmask(), '0xff000000', 'Got correct hexmask for IPv4 range');
is($ip->prefix(), '1.0.0.0/8', 'Got correct prefix for IPv4 range');
is($ip->mask(), '255.0.0.0', 'Got correct mask for IPv4 range');
is($ip->iptype(), 'PUBLIC', 'Got correct iptype for IPv4 range');
is($ip->reverse_ip(), '1.in-addr.arpa.', 'Got correct reverse_ip for IPv4 range');
is($ip->last_bin(), ('0' x 7).('1' x 25), 'Got correct last_bin for IPv4 range');
is($ip->last_int(), 0x1FFFFFF, 'Got correct last_int for IPv4 range');
is($ip->last_ip(), '1.255.255.255', 'Got correct last_ip for IPv4 range');

$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->intip(), 16777216, 'Got correct intip for IPv4 range');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->binip(), '00000001000000000000000000000000',
    'binip is correct');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->prefixlen(), 8, 'prefixlen is correct');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
ok($ip->is_prefix(), 'is_prefix is correct');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->ip(), '1.0.0.0', 'ip is correct');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->version(), 4, 'ipversion is correct');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->binmask(), '11111111000000000000000000000000', 'binmask is correct');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->last_bin(), '00000001111111111111111111111111', 'last_bin is correct');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->print(), '1/8', 'Got correct printed value');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->size(), 16777216, 'Got correct size');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->intip(), '16777216', 'Got correct intip for IPv4 range');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->hexip(), '0x1000000', 'Got correct hexip for IPv4 range');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->hexmask(), '0xff000000', 'Got correct hexmask for IPv4 range');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->prefix(), '1.0.0.0/8', 'Got correct prefix for IPv4 range');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->mask(), '255.0.0.0', 'Got correct mask for IPv4 range');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->iptype(), 'PUBLIC', 'Got correct iptype for IPv4 range');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->reverse_ip(), '1.in-addr.arpa.', 'Got correct reverse_ip for IPv4 range');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->last_bin(), ('0' x 7).('1' x 25), 'Got correct last_bin for IPv4 range');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->last_int(), 0x1FFFFFF, 'Got correct last_int for IPv4 range');
$ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255', 4);
is($ip->last_ip(), '1.255.255.255', 'Got correct last_ip for IPv4 range');

my $ip2 = Net::IP::XS->new('2/8');
ok($ip->bincomp('lt', $ip2), "Range's first address is smaller than other range's");
my $ip3 = $ip->binadd($ip2);
ok($ip3, 'Got result on binadd of two IP addresses');
is($ip3->ip(), '3.0.0.0', 'Newly created IP is correct');

my $agg1_ip = Net::IP::XS->new('0.0.0.0 - 0.255.255.255');
my $agg2_ip = Net::IP::XS->new('1.0.0.0 - 1.255.255.255');
my $agg3_ip = $agg1_ip->aggregate($agg2_ip);
ok($agg3_ip, 'Got result on aggregate of two IP ranges');
is($agg3_ip->ip(), '0.0.0.0', 'Starting IP is correct');
is($agg3_ip->last_ip(), '1.255.255.255', 'Ending IP is correct');
is($agg3_ip->prefixlen(), 7, 'Ending IP is correct');

is($agg1_ip->overlaps($agg2_ip), $IP_NO_OVERLAP, 'Ranges do not overlap');
is($agg2_ip->overlaps($agg1_ip), $IP_NO_OVERLAP, 'Ranges do not overlap (2)');
is($agg1_ip->overlaps($agg3_ip), $IP_A_IN_B_OVERLAP, 'Range A is in range B');
is($agg3_ip->overlaps($agg1_ip), $IP_B_IN_A_OVERLAP, 'Range B is in range A');
is($agg3_ip->overlaps($agg3_ip), $IP_IDENTICAL, 'Range is identical to range');

$agg1_ip = Net::IP::XS->new('0.0.0.0 - 0.255.255.255');
$agg2_ip = Net::IP::XS->new('2.0.0.0 - 1.255.255.255');
$agg3_ip = $agg1_ip->aggregate($agg2_ip);
is($agg3_ip, undef, 'aggregate failed');

$ip = Net::IP::XS->new('0000:0000:0000:0000:0000:0000:0000:0000 - FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF', 6);
ok((blessed $ip and $ip->isa('Net::IP::XS')),
    'IP object is blessed and has correct package');
is($ip->size(), '340282366920938463463374607431768211456',
    'Got correct size for IPv6');
is($ip->size(), '340282366920938463463374607431768211456',
    'Got correct size for IPv6 (2)');

$ip = Net::IP::XS->new('0000:: - FFFF::', 6);
ok((blessed $ip and $ip->isa('Net::IP::XS')),
    'IP object is blessed and has correct package');

$ip = Net::IP::XS->new('::/0', 6);
ok((blessed $ip and $ip->isa('Net::IP::XS')),
    'IP object is blessed and has correct package');

$ip = Net::IP::XS->new('::/0', 6);
is($ip->size(), '340282366920938463463374607431768211456',
    'Got correct size for IPv6');
is($ip->intip(), 0, 'Got correct intip for IPv6 range');
is($ip->hexip(), '0x0', 'Got correct hexip for IPv6 range');
is($ip->hexmask(), '0x0', 'Got correct hexmask for IPv6 range');
is($ip->prefix(), '0000:0000:0000:0000:0000:0000:0000:0000/0', 
    'Got correct prefix for IPv6 range');
is($ip->mask(), '0000:0000:0000:0000:0000:0000:0000:0000', 
    'Got correct mask for IPv6 range');
is($ip->iptype(), 'UNSPECIFIED',
    'Got correct iptype for range');
is($ip->reverse_ip(), 'ip6.arpa.', 'Got correct iptype for range');
is($ip->last_bin(), '1' x 128, 'Got correct lastbin for range');
is($ip->last_int(), '340282366920938463463374607431768211455',
    'Got correct last_int for range');
is($ip->last_ip(), 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
    'Got correct last_ip for range');
is($ip->short(), '::', 'Got correct short for IPv6 range');

$ip->{'last_bin'} = '1' x 256;
delete $ip->{'last_ip'};
is($ip->last_ip(), undef, 'Got undef on last_ip for bad last_bin');

$ip = Net::IP::XS->new('::/0', 6);
$ip->{'is_prefix'} = 0;
delete $ip->{'ip'};
is($ip->print(), undef, 'Got undef on print for bad object');

$ip = Net::IP::XS->new('::/0', 6);
$ip->{'is_prefix'} = 0;
delete $ip->{'ip'};
is($ip->mask(), undef, 'Got undef on mask for bad object');

$ip = Net::IP::XS->new('::/0', 6);
$ip->{'binmask'} = '1' x 256;
is($ip->mask(), undef, 'Got undef on mask for bad object');

$ip = Net::IP::XS->new('::/0', 6);
delete $ip->{'last_bin'};
is($ip->last_bin(), '1' x 128, 'Got correct last_bin value after '.
                               'deleting the original (1)');
$ip = Net::IP::XS->new('::/0', 6);
delete $ip->{'last_bin'};
$ip->{'is_prefix'} = 0;
is($ip->last_bin(), '1' x 128, 'Got correct last_bin value after '.
                               'deleting the original (2)');
$ip = Net::IP::XS->new('::/0', 6);
delete $ip->{'last_bin'};
delete $ip->{'last_ip'};
$ip->{'is_prefix'} = 0;
is($ip->last_bin(), undef, 'Got undef last_bin on bad object (1)');

$ip = Net::IP::XS->new('::/0', 6);
delete $ip->{'last_bin'};
$ip->{'last_ip'} = 'ZXCV';
$ip->{'is_prefix'} = 0;
is($ip->last_bin(), undef, 'Got undef last_bin on bad object (2)');

# (Making sure that each method works if it is called immediately
# after new is called. (Repeated calls are for checking that the
# values were cached.))
$ip = Net::IP::XS->new('::/0', 6);
is($ip->size(), '340282366920938463463374607431768211456',
    'Got correct size for IPv6');
$ip = Net::IP::XS->new('::/0', 6);
is($ip->intip(), 0, 'Got correct intip for IPv6 range');
$ip = Net::IP::XS->new('::/0', 6);
is($ip->hexip(), '0x0', 'Got correct hexip for IPv6 range');
is($ip->hexip(), '0x0', 'Got correct hexip for IPv6 range');
$ip = Net::IP::XS->new('::/0', 6);
is($ip->hexmask(), '0x0', 'Got correct hexmask for IPv6 range');
is($ip->hexmask(), '0x0', 'Got correct hexmask for IPv6 range');
$ip = Net::IP::XS->new('::/0', 6);
is($ip->prefix(), '0000:0000:0000:0000:0000:0000:0000:0000/0', 
    'Got correct prefix for IPv6 range');
is($ip->prefix(), '0000:0000:0000:0000:0000:0000:0000:0000/0', 
    'Got correct prefix for IPv6 range');
$ip = Net::IP::XS->new('::/0', 6);
is($ip->mask(), '0000:0000:0000:0000:0000:0000:0000:0000', 
    'Got correct mask for IPv6 range');
is($ip->mask(), '0000:0000:0000:0000:0000:0000:0000:0000', 
    'Got correct mask for IPv6 range');
$ip = Net::IP::XS->new('::/0', 6);
is($ip->iptype(), 'UNSPECIFIED',
    'Got correct iptype for range');
is($ip->iptype(), 'UNSPECIFIED',
    'Got correct iptype for range');
$ip = Net::IP::XS->new('::/0', 6);
is($ip->reverse_ip(), 'ip6.arpa.', 'Got correct iptype for range');
$ip = Net::IP::XS->new('::/0', 6);
is($ip->last_bin(), '1' x 128, 'Got correct lastbin for range');
$ip = Net::IP::XS->new('::/0', 6);
is($ip->last_int(), '340282366920938463463374607431768211455',
    'Got correct last_int for range');
is($ip->last_int(), '340282366920938463463374607431768211455',
    'Got correct last_int for range');
$ip = Net::IP::XS->new('::/0', 6);
is($ip->last_ip(), 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
    'Got correct last_ip for range');

$ip2 = Net::IP::XS->new('2000::/16');
ok($ip->bincomp('lt', $ip2), "Range's first address is smaller than other range's");
$ip3 = $ip->binadd($ip2);
ok($ip3, 'Got result on binadd of two IP addresses');
is($ip3->ip(), '2000:0000:0000:0000:0000:0000:0000:0000', 'Newly created IP is correct');

$agg1_ip = Net::IP::XS->new('0000::/16');
$agg2_ip = Net::IP::XS->new('0001::/16');
$agg3_ip = $agg1_ip->aggregate($agg2_ip);
ok($agg3_ip, 'Got result on aggregate of two IP ranges');
is($agg3_ip->ip(), '0000:0000:0000:0000:0000:0000:0000:0000', 'Starting IP is correct');
is($agg3_ip->last_ip(), '0001:ffff:ffff:ffff:ffff:ffff:ffff:ffff', 'Ending IP is correct');
is($agg3_ip->prefixlen(), 15, 'Prefix length is correct');

is($agg1_ip->overlaps($agg2_ip), $IP_NO_OVERLAP, 'Ranges do not overlap');
is($agg2_ip->overlaps($agg1_ip), $IP_NO_OVERLAP, 'Ranges do not overlap (2)');
is($agg1_ip->overlaps($agg3_ip), $IP_A_IN_B_OVERLAP, 'Range A is in range B');
is($agg3_ip->overlaps($agg1_ip), $IP_B_IN_A_OVERLAP, 'Range B is in range A');
is($agg3_ip->overlaps($agg3_ip), $IP_IDENTICAL, 'Range is identical to range');

$ip = Net::IP::XS->new('0/0');
is($ip->intip(), '0', 'Got correct intip for 0/0');

$ip = Net::IP::XS->new('61-217-102-8.hinet-ip.hinet.net');
ok((not $ip), 'Failed on bad IP address');

$ip = Net::IP::XS->new('123.0.0.1/a');
ok((not $ip), 'Failed on bad IP address');

$ip = Net::IP::XS->new('123.0.0.1/a');
ok((not $ip), 'Failed on bad IP address');

$ip = Net::IP::XS->new('FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF');
ok($ip, 'Got new IP object');

eval { require IP::Authority };
my $has_ip_authority = (not $@);
SKIP: {
    skip "IP::Authority not available", 5 unless $has_ip_authority;

    $ip = Net::IP::XS->new('202/8');
    is($ip->auth(), 'AP', 'Got correct auth information');
    is($ip->auth(), 'AP', 'Got correct auth information (cached)');

    $ip = Net::IP::XS->new('2000::');
    is($ip->auth(), undef, 'Got undef for auth for IPv6 address');
    is($ip->error(), 'Cannot get auth information: Not an IPv4 address',
        'Got correct error');
    is($ip->errno(), 308, 'Got correct errno');
};

$ip->{'ipversion'} = 0;
my @prefixes = $ip->find_prefixes();
is_deeply(\@prefixes, [], 'No prefixes where version is zero');

$ip = Net::IP::XS->new('127.0.0.1', 8);
is($ip, undef, "Got undef IP object on bad version");

my $ip1 = Net::IP::XS->new('0000::');
$ip2 = Net::IP::XS->new('1111::');
delete $ip1->{'binip'};
delete $ip2->{'binip'};
is($ip1->bincomp('lt', $ip2), 0, 'bincomp depends on binip');

$ip1 = Net::IP::XS->new('0000::');
$ip2 = Net::IP::XS->new('1111::');
is($ip1->bincomp('asdf', $ip2), undef, 'bincomp failed on bad operator');

$ip1 = Net::IP::XS->new('0000::');
$ip2 = Net::IP::XS->new('1111::');
delete $ip1->{'binip'};
delete $ip2->{'binip'};
$ip3 = $ip1->binadd($ip2);
is($ip3->binip(), '0' x 128, 'binadd depends on binip');

$ip1 = Net::IP::XS->new('0000::');
$ip2 = Net::IP::XS->new('1111::');
$ip1->{'binip'} = '0';
$ip2->{'binip'} = '01';
$ip3 = $ip1->binadd($ip2);
is($ip3, undef, 'binadd depends on binip (2)');

$ip1 = Net::IP::XS->new('0000::');
$ip2 = Net::IP::XS->new('1111::');
delete $ip1->{'ipversion'};
is($ip1->overlaps($ip2), undef, "overlaps depends on first ".
                                "object's version");

$ip1 = Net::IP::XS->new('0000::');
$ip2 = Net::IP::XS->new('1111::');
delete $ip1->{'ipversion'};
is($ip1->aggregate($ip2), undef, "aggregate depends on first ".
                                 "object's version");

$ip1 = Net::IP::XS->new('0000::');
$ip2 = Net::IP::XS->new('1111::');
is($ip1->aggregate($ip2), undef, "aggregate failed");

$ip1 = Net::IP::XS->new('::1');
delete $ip1->{'last_int'};
is($ip1->last_int(), 1, 'Got correct last_int where cached value deleted');

# Use an empty hashref for the object, make sure all methods bar mask
# and last_ip return a false value (mask and last_ip should return the
# zero IPv6 address).

$ip = bless {}, 'Net::IP::XS';
for (qw(binip prefixlen is_prefix ip version binmask last_bin
        print size intip hexip hexmask prefix iptype reverse_ip
        last_int)) {
    ok((not $ip->$_()), "Got false value for $_");
}
    
for (qw(mask last_ip)) {
    is($ip->$_(), (join ':', ('0000') x 8),
        "Got zero IPv6 address for $_");
}

# Replace all fields with garbage, make sure it doesn't segfault.

$ip = Net::IP::XS->new('::/0');
for (keys %{$ip}) {
    $ip->{$_} = join '', map { chr(rand(256)) } (0..10000);
}

$c->start();
for (qw(binip prefixlen is_prefix ip version binmask last_bin
        print size intip hexip hexmask prefix mask iptype reverse_ip
        last_int last_ip)) {
    $ip->$_();
}
$c->stop();

ok(1, "Called all methods successfully");

# Call all object methods with a non-Net::IP::XS object, confirm no
# segfaults or similar.

my $str = 'asdf';
my $object = bless \$str, 'not_net_ip_xs';
$c->start();
for (qw(binip prefixlen is_prefix ip version binmask last_bin
        print size intip hexip hexmask prefix mask iptype reverse_ip
        last_int last_ip ip_add_num)) {
    my $fn = "Net::IP::XS::$_";
    my $res = eval { $fn->($object) };
}
for (qw(bincomp binadd aggregate overlaps)) {
    my $fn = "Net::IP::XS::$_";
    my $res = eval { $fn->($object, $object) };
}

$c->stop();

ok(1, 'Called all methods on non-Net::IP::XS object');

1;

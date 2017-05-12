#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

use lib './lib';

use_ok('Net::IPAddress::Filter') or die "Unable to compile Net::IPAddress::Filter" ;

my $filter = new_ok('Net::IPAddress::Filter') or die "Unable to construct a Net::IPAddress::Filter";

{
    # Check off-by-one errors for a single-address range.
    my $filter = Net::IPAddress::Filter->new();
    ok(!$filter->in_filter('192.168.1.0'), "192.168.1.0 not yet in filter");
    ok(!$filter->in_filter('192.168.1.1'), "192.168.1.1 not yet in filter");
    ok(!$filter->in_filter('192.168.1.2'), "192.168.1.2 not yet in filter");
    ok($filter->add_range('192.168.1.1'),  "Adding 192.168.1.1 to filter");
    ok(!$filter->in_filter('192.168.1.0'), "192.168.1.0 still not in filter");
    ok($filter->in_filter('192.168.1.1'),  "192.168.1.1 now in filter");
    ok(!$filter->in_filter('192.168.1.2'), "192.168.1.2 still not in filter");
}

{
    # Check off-by-one errors for an actual range.
    my $filter = Net::IPAddress::Filter->new();
    ok(!$filter->in_filter('10.1.100.0'),               "10.1.100.0 not yet in filter");
    ok(!$filter->in_filter('10.1.100.1'),               "10.1.100.1 not yet in filter");
    ok(!$filter->in_filter('10.1.100.2'),               "10.1.100.2 not yet in filter");
    ok(!$filter->in_filter('10.1.100.98'),              "10.1.100.98 not yet in filter");
    ok(!$filter->in_filter('10.1.100.99'),              "10.1.100.99 not yet in filter");
    ok(!$filter->in_filter('10.1.100.100'),             "10.1.100.100 not yet in filter");
    ok($filter->add_range('10.1.100.1', '10.1.100.99'), "Adding ('10.1.100.1', '10.1.100.99') to filter");
    ok(!$filter->in_filter('10.1.100.0'),               "10.1.100.0 still not in filter");
    ok($filter->in_filter('10.1.100.1'),                "10.1.100.1 now in filter");
    ok($filter->in_filter('10.1.100.2'),                "10.1.100.2 now in filter");
    ok($filter->in_filter('10.1.100.98'),               "10.1.100.98 now in filter");
    ok($filter->in_filter('10.1.100.99'),               "10.1.100.99 now in filter");
    ok(!$filter->in_filter('10.1.100.100'),             "10.1.100.100 still not in filter");
}

{
    # Check out-of-order range
    my $filter = Net::IPAddress::Filter->new();
    ok($filter->add_range('127.0.0.10', '127.0.0.1'), "Adding ('127.0.0.10', '127.0.0.1') to filter");
    ok($filter->in_filter('127.0.0.5'),               "127.0.0.5 now in filter");
}

{
    # Check zero-padded inputs a la ipfilter.dat
    my $filter = Net::IPAddress::Filter->new();
    ok($filter->add_range('127.000.000.099', '127.000.000.099'), "Adding ('127.000.000.099', '127.000.000.099') to filter");
    ok($filter->in_filter('127.000.000.099'),                    "127.000.000.099 now in filter");
}

{
    # Check overlapping ranges
    my $filter = Net::IPAddress::Filter->new();
    ok($filter->add_range('172.16.0.100', '172.16.0.200'), "Adding ('172.16.0.100', '172.16.0.200') to filter");
    ok($filter->add_range('172.16.0.199', '172.16.0.255'), "Adding ('172.16.0.199', '172.16.0.255') to filter");
    ok($filter->in_filter('172.16.0.199'),                 "172.16.0.199 now in filter");
    ok($filter->in_filter('172.16.0.200'),                 "172.16.0.200 now in filter");
    ok($filter->in_filter('172.16.0.201'),                 "172.16.0.201 now in filter");
}

{
    # Check CIDR ranges.
    my $filter = Net::IPAddress::Filter->new();
    ok($filter->add_range('127.1.0.0/32'),   "Adding CIDR 127.1.0.0/32 to filter");
    ok(!$filter->in_filter('127.0.255.255'), "127.0.255.255 not in filter");
    ok($filter->in_filter('127.1.0.0'),      "127.1.0.0 now in filter");
    ok(!$filter->in_filter('127.1.0.1'),     "127.1.0.1 not in filter");

    ok($filter->add_range('127.100.0.0/24'),  "Adding CIDR 127.100.0.0/24 to filter");
    ok(!$filter->in_filter('127.99.255.255'), "127.99.255.255 not in filter");
    ok($filter->in_filter('127.100.0.0'),     "127.100.0.0 now in filter");
    ok($filter->in_filter('127.100.0.255'),   "127.100.0.255 now in filter");
    ok(!$filter->in_filter('127.100.1.0'),    "127.100.1.0 not in filter");

}

SKIP: {
    if ( $Set::IntervalTree::VERSION < 0.03 ) {
        skip("2^31 bug in Set::IntervalTree which Net::IPAddress::Filter uses. Fixed in 0.03", 2);
    }
    my $filter = Net::IPAddress::Filter->new();
    ok($filter->add_range('0.0.0.1', '0.0.0.2'), "Adding ('0.0.0.1', '0.0.0.2') to filter");
    ok(!$filter->in_filter('128.0.0.0'),         "128.0.0.0 not in filter (2^31 bug)");
}

{
    # Check setting and getting scalar values with each range.
    my $filter = Net::IPAddress::Filter->new();
    my $value1 = "0.0.0.1 ==> 0.0.0.2";
    ok($filter->add_range_with_value($value1, '0.0.0.1', '0.0.0.2'), "Adding ('0.0.0.1', '0.0.0.2') to filter");
    my $value2 = 'CIDR 0.0.0.1/32';
    ok($filter->add_range_with_value($value2, '0.0.0.1/32'), "Adding '0.0.0.1/32' to filter");
    is_deeply($filter->get_matches('0.0.0.1'), [ $value1, $value2 ], "get_matches() returns expected value fields");
    is_deeply($filter->get_matches('0.0.0.3'), [ ], "get_matches() off-by-one check");
}

done_testing;


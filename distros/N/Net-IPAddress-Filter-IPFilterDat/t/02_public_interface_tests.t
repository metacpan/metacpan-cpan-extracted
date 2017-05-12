#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

use_ok('Net::IPAddress::Filter::IPFilterDat') or die "Unable to compile Net::IPAddress::Filter::IPFilterDat" ;

run_baseclass_tests();
run_specific_ipfilter_tests();

done_testing;

exit;

sub run_specific_ipfilter_tests {

    my $filter = new_ok('Net::IPAddress::Filter::IPFilterDat') or die "Unable to construct a Net::IPAddress::Filter::IPFilterDat";

    # Add individual rules
    ok($filter->add_rule("10.1.100.100 - 10.1.100.200 , 000 , SomeRandom"), "Childclass: Adding 10.1.100.100-200 to filter");
    ok($filter->in_filter('10.1.100.150'), "Childclass: 10.1.100.150 now in filter");
    ok($filter->add_rule("10.1.200.000 - 10.1.200.100 , 000 , SomeRandom\n"), "Childclass: Adding 10.1.200.000-100\\n to filter");
    ok($filter->in_filter('10.1.200.050'), "Childclass: 10.1.200.050 now in filter");

    # Load rules from a file
    my $rules_added = $filter->load_file('t/ipfilter.dat.1');
    is($rules_added, 2, "Childclass: Added 2 rules from t/ipfilter.dat.1");
    ok($filter->in_filter('192.168.1.100'), "Childclass: 192.168.1.100 now in filter");

    # Load rules from a filehandle
    open my $FH, '<', 't/ipfilter.dat.2' or die "Unable to open t/ipfilter.dat.2 for reading: $!";
    $rules_added = $filter->load_file($FH);
    is($rules_added, 1, "Childclass: Added 1 rule from t/ipfilter.dat.2 filehandle");
    ok($filter->in_filter('127.0.0.100'), "Childclass: 127.0.0.100 now in filter");

}

sub run_baseclass_tests {

    my $filter = new_ok('Net::IPAddress::Filter::IPFilterDat') or die "Unable to construct a Net::IPAddress::Filter::IPFilterDat";

    # Check off-by-one errors for a single-address range.
    ok(!$filter->in_filter('192.168.1.0'), "Baseclass: 192.168.1.0 not yet in filter");
    ok(!$filter->in_filter('192.168.1.1'), "Baseclass: 192.168.1.1 not yet in filter");
    ok(!$filter->in_filter('192.168.1.2'), "Baseclass: 192.168.1.2 not yet in filter");
    ok($filter->add_range('192.168.1.1'), "Baseclass: Adding 192.168.1.1 to filter");
    ok(!$filter->in_filter('192.168.1.0'), "Baseclass: 192.168.1.0 still not in filter");
    ok($filter->in_filter('192.168.1.1'), "Baseclass: 192.168.1.1 now in filter");
    ok(!$filter->in_filter('192.168.1.2'), "Baseclass: 192.168.1.2 still not in filter");

    # Check off-by-one errors for an actual range.
    ok(!$filter->in_filter('10.1.100.0'), "Baseclass: 10.1.100.0 not yet in filter");
    ok(!$filter->in_filter('10.1.100.1'), "Baseclass: 10.1.100.1 not yet in filter");
    ok(!$filter->in_filter('10.1.100.2'), "Baseclass: 10.1.100.2 not yet in filter");
    ok(!$filter->in_filter('10.1.100.98'), "Baseclass: 10.1.100.98 not yet in filter");
    ok(!$filter->in_filter('10.1.100.99'), "Baseclass: 10.1.100.99 not yet in filter");
    ok(!$filter->in_filter('10.1.100.100'), "Baseclass: 10.1.100.100 not yet in filter");
    ok($filter->add_range('10.1.100.1', '10.1.100.99'), "Baseclass: Adding ('10.1.100.1', '10.1.100.99') to filter");
    ok(!$filter->in_filter('10.1.100.0'), "Baseclass: 10.1.100.0 still not in filter");
    ok($filter->in_filter('10.1.100.1'), "Baseclass: 10.1.100.1 now in filter");
    ok($filter->in_filter('10.1.100.2'), "Baseclass: 10.1.100.2 now in filter");
    ok($filter->in_filter('10.1.100.98'), "Baseclass: 10.1.100.98 now in filter");
    ok($filter->in_filter('10.1.100.99'), "Baseclass: 10.1.100.99 now in filter");
    ok(!$filter->in_filter('10.1.100.100'), "Baseclass: 10.1.100.100 still not in filter");

    # Check out-of-order range
    ok($filter->add_range('127.0.0.10', '127.0.0.1'), "Baseclass: Adding ('127.0.0.10', '127.0.0.1') to filter");
    ok($filter->in_filter('127.0.0.5'), "Baseclass: 127.0.0.5 now in filter");

    # Check zero-padded inputs a la ipfilter.dat
    ok($filter->add_range('127.000.000.099', '127.000.000.099'), "Baseclass: Adding ('127.000.000.099', '127.000.000.099') to filter");
    ok($filter->in_filter('127.000.000.099'), "Baseclass: 127.000.000.099 now in filter");

    # Check overlapping ranges
    ok($filter->add_range('172.16.0.100', '172.16.0.200'), "Baseclass: Adding ('172.16.0.100', '172.16.0.200') to filter");
    ok($filter->add_range('172.16.0.199', '172.16.0.255'), "Baseclass: Adding ('172.16.0.199', '172.16.0.255') to filter");
    ok($filter->in_filter('172.16.0.199'), "Baseclass: 172.16.0.199 now in filter");
    ok($filter->in_filter('172.16.0.200'), "Baseclass: 172.16.0.200 now in filter");
    ok($filter->in_filter('172.16.0.201'), "Baseclass: 172.16.0.201 now in filter");
}


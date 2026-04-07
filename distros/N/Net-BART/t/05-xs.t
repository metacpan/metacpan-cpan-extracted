#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Net::BART::XS };
    if ($@) {
        plan skip_all => "Net::BART::XS not built: $@";
    }
}

# Basic insert and lookup
{
    my $t = Net::BART::XS->new;
    ok($t->insert("10.0.0.0/8", "ten"), 'insert 10/8');
    is($t->size, 1, 'size is 1');

    my ($val, $ok) = $t->lookup("10.1.2.3");
    ok($ok, 'lookup found');
    is($val, "ten", 'lookup returns correct value');

    ($val, $ok) = $t->lookup("11.0.0.0");
    ok(!$ok, 'lookup misses non-matching IP');
}

# Longest prefix match
{
    my $t = Net::BART::XS->new;
    $t->insert("10.0.0.0/8", "a");
    $t->insert("10.1.0.0/16", "b");
    $t->insert("10.1.2.0/24", "c");

    my ($val, $ok) = $t->lookup("10.1.2.3");
    is($val, "c", 'LPM returns most specific /24');

    ($val) = $t->lookup("10.1.3.1");
    is($val, "b", 'LPM returns /16 for 10.1.3.x');

    ($val) = $t->lookup("10.2.0.1");
    is($val, "a", 'LPM returns /8 for 10.2.x.x');
}

# Exact match get
{
    my $t = Net::BART::XS->new;
    $t->insert("10.0.0.0/8", "a");
    $t->insert("10.1.0.0/16", "b");

    my ($val, $ok) = $t->get("10.0.0.0/8");
    ok($ok, 'exact match found');
    is($val, "a");

    ($val, $ok) = $t->get("10.2.0.0/16");
    ok(!$ok, 'exact match not found for non-existent prefix');
}

# Contains
{
    my $t = Net::BART::XS->new;
    $t->insert("10.0.0.0/8", 1);

    ok($t->contains("10.0.0.1"), 'contains 10.0.0.1');
    ok($t->contains("10.255.255.255"), 'contains 10.255.255.255');
    ok(!$t->contains("11.0.0.0"), 'does not contain 11.0.0.0');
}

# Delete
{
    my $t = Net::BART::XS->new;
    $t->insert("10.0.0.0/8", "a");
    $t->insert("10.1.0.0/16", "b");

    my ($old, $ok) = $t->delete("10.1.0.0/16");
    ok($ok, 'delete found');
    is($old, "b", 'delete returns old value');
    is($t->size, 1, 'size decreased');

    my ($val);
    ($val, $ok) = $t->lookup("10.1.2.3");
    is($val, "a", 'after delete, LPM falls back to /8');
}

# Update existing prefix
{
    my $t = Net::BART::XS->new;
    ok($t->insert("10.0.0.0/8", "old"), 'first insert is new');
    ok(!$t->insert("10.0.0.0/8", "new"), 'second insert is update');
    is($t->size, 1, 'size unchanged after update');

    my ($val) = $t->get("10.0.0.0/8");
    is($val, "new", 'value updated');
}

# Host routes (/32)
{
    my $t = Net::BART::XS->new;
    $t->insert("10.1.2.3/32", "host");

    my ($val, $ok) = $t->lookup("10.1.2.3");
    is($val, "host", 'host route matches');

    ($val, $ok) = $t->lookup("10.1.2.4");
    ok(!$ok, 'host route does not match other IPs');
}

# Default route
{
    my $t = Net::BART::XS->new;
    $t->insert("0.0.0.0/0", "default");
    $t->insert("10.0.0.0/8", "ten");

    my ($val) = $t->lookup("10.1.2.3");
    is($val, "ten", 'more specific wins over default');

    ($val) = $t->lookup("192.168.1.1");
    is($val, "default", 'default matches unmatched IPs');
}

# IPv6
{
    my $t = Net::BART::XS->new;
    $t->insert("2001:db8::/32", "doc");
    $t->insert("2001:db8:1::/48", "subnet1");

    my ($val, $ok) = $t->lookup("2001:db8:1::1");
    ok($ok);
    is($val, "subnet1", 'IPv6 LPM works');

    ($val) = $t->lookup("2001:db8:2::1");
    is($val, "doc", 'IPv6 LPM falls back');

    ($val, $ok) = $t->lookup("2001:db9::1");
    ok(!$ok, 'IPv6 miss');

    is($t->size6, 2, 'IPv6 size');
}

# Mixed IPv4 and IPv6
{
    my $t = Net::BART::XS->new;
    $t->insert("10.0.0.0/8", "v4");
    $t->insert("2001:db8::/32", "v6");

    is($t->size, 2);
    is($t->size4, 1);
    is($t->size6, 1);
}

# Non-octet-aligned prefixes
{
    my $t = Net::BART::XS->new;
    $t->insert("10.0.0.0/12", "twelve");
    $t->insert("10.16.0.0/12", "twelve-2");

    my ($val) = $t->lookup("10.15.255.255");
    is($val, "twelve", '/12 prefix matches');

    ($val) = $t->lookup("10.16.0.1");
    is($val, "twelve-2", 'second /12 prefix matches');
}

# Many prefixes
{
    my $t = Net::BART::XS->new;
    for my $i (0 .. 255) {
        $t->insert("10.0.$i.0/24", "net-$i");
    }
    is($t->size, 256, '256 prefixes inserted');

    for my $i (0, 127, 255) {
        my ($val) = $t->lookup("10.0.$i.1");
        is($val, "net-$i", "lookup in /24 net-$i");
    }
}

done_testing;

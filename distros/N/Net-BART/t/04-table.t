#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'lib';
use Net::BART;

# Basic insert and lookup
{
    my $t = Net::BART->new;
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
    my $t = Net::BART->new;
    $t->insert("10.0.0.0/8", "a");
    $t->insert("10.1.0.0/16", "b");
    $t->insert("10.1.2.0/24", "c");

    my ($val, $ok) = $t->lookup("10.1.2.3");
    ok($ok);
    is($val, "c", 'LPM returns most specific /24');

    ($val, $ok) = $t->lookup("10.1.3.1");
    ok($ok);
    is($val, "b", 'LPM returns /16 for 10.1.3.x');

    ($val, $ok) = $t->lookup("10.2.0.1");
    ok($ok);
    is($val, "a", 'LPM returns /8 for 10.2.x.x');
}

# Exact match get
{
    my $t = Net::BART->new;
    $t->insert("10.0.0.0/8", "a");
    $t->insert("10.1.0.0/16", "b");

    my ($val, $ok) = $t->get("10.0.0.0/8");
    ok($ok, 'exact match found');
    is($val, "a");

    ($val, $ok) = $t->get("10.1.0.0/16");
    ok($ok);
    is($val, "b");

    ($val, $ok) = $t->get("10.2.0.0/16");
    ok(!$ok, 'exact match not found for non-existent prefix');
}

# Contains
{
    my $t = Net::BART->new;
    $t->insert("10.0.0.0/8", 1);

    ok($t->contains("10.0.0.1"), 'contains 10.0.0.1');
    ok($t->contains("10.255.255.255"), 'contains 10.255.255.255');
    ok(!$t->contains("11.0.0.0"), 'does not contain 11.0.0.0');
}

# Delete
{
    my $t = Net::BART->new;
    $t->insert("10.0.0.0/8", "a");
    $t->insert("10.1.0.0/16", "b");

    is($t->size, 2);

    my ($old, $ok) = $t->delete("10.1.0.0/16");
    ok($ok, 'delete found');
    is($old, "b", 'delete returns old value');
    is($t->size, 1);

    my ($val);
    ($val, $ok) = $t->lookup("10.1.2.3");
    ok($ok);
    is($val, "a", 'after delete, LPM falls back to /8');

    ($old, $ok) = $t->delete("10.1.0.0/16");
    ok(!$ok, 'double delete returns not found');
}

# Update existing prefix
{
    my $t = Net::BART->new;
    ok($t->insert("10.0.0.0/8", "old"), 'first insert is new');
    ok(!$t->insert("10.0.0.0/8", "new"), 'second insert is update');
    is($t->size, 1, 'size unchanged after update');

    my ($val) = $t->get("10.0.0.0/8");
    is($val, "new", 'value updated');
}

# Host routes (/32)
{
    my $t = Net::BART->new;
    $t->insert("10.1.2.3/32", "host");

    my ($val, $ok) = $t->lookup("10.1.2.3");
    ok($ok);
    is($val, "host", 'host route matches');

    ($val, $ok) = $t->lookup("10.1.2.4");
    ok(!$ok, 'host route does not match other IPs');
}

# Default route
{
    my $t = Net::BART->new;
    $t->insert("0.0.0.0/0", "default");

    my ($val, $ok) = $t->lookup("1.2.3.4");
    ok($ok);
    is($val, "default", 'default route matches any IP');

    $t->insert("10.0.0.0/8", "ten");
    ($val, $ok) = $t->lookup("10.1.2.3");
    ok($ok);
    is($val, "ten", 'more specific wins over default');

    ($val, $ok) = $t->lookup("192.168.1.1");
    ok($ok);
    is($val, "default", 'default still matches unmatched IPs');
}

# IPv6
{
    my $t = Net::BART->new;
    $t->insert("2001:db8::/32", "doc");
    $t->insert("2001:db8:1::/48", "subnet1");

    my ($val, $ok) = $t->lookup("2001:db8:1::1");
    ok($ok);
    is($val, "subnet1", 'IPv6 LPM works');

    ($val, $ok) = $t->lookup("2001:db8:2::1");
    ok($ok);
    is($val, "doc", 'IPv6 LPM falls back');

    ($val, $ok) = $t->lookup("2001:db9::1");
    ok(!$ok, 'IPv6 miss');

    is($t->size6, 2, 'IPv6 size');
}

# Mixed IPv4 and IPv6
{
    my $t = Net::BART->new;
    $t->insert("10.0.0.0/8", "v4");
    $t->insert("2001:db8::/32", "v6");

    is($t->size, 2);
    is($t->size4, 1);
    is($t->size6, 1);

    my ($v4) = $t->lookup("10.1.2.3");
    is($v4, "v4");

    my ($v6) = $t->lookup("2001:db8::1");
    is($v6, "v6");
}

# Walk
{
    my $t = Net::BART->new;
    $t->insert("10.0.0.0/8", "a");
    $t->insert("192.168.0.0/16", "b");

    my %seen;
    $t->walk(sub {
        my ($prefix, $value) = @_;
        $seen{$prefix} = $value;
    });

    is(scalar keys %seen, 2, 'walk visits all prefixes');
    is($seen{"10.0.0.0/8"}, "a", 'walk: 10/8');
    is($seen{"192.168.0.0/16"}, "b", 'walk: 192.168/16');
}

# Non-octet-aligned prefixes
{
    my $t = Net::BART->new;
    $t->insert("10.0.0.0/12", "twelve");
    $t->insert("10.16.0.0/12", "twelve-2");

    my ($val, $ok) = $t->lookup("10.15.255.255");
    ok($ok);
    is($val, "twelve", '/12 prefix matches');

    ($val, $ok) = $t->lookup("10.16.0.1");
    ok($ok);
    is($val, "twelve-2", 'second /12 prefix matches');

    ($val, $ok) = $t->lookup("10.32.0.1");
    ok(!$ok, 'outside /12 range');
}

# Many prefixes (stress test)
{
    my $t = Net::BART->new;
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

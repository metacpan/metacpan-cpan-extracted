#!/usr/bin/perl

use Test::More tests => 2;
use Carp;

use strict;
use warnings;

use Net::DAV::UUID ();

my $uuid = Net::DAV::UUID::generate("/foo/bar/baz", "tom");

ok($uuid =~ /^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/, "UUID generator produces a correctly-formatted identifier");

my %uuids = ();

$uuids{Net::DAV::UUID::generate("/foo/bar/baz", "tom")} = 1 foreach (1..10000);

is( (scalar keys %uuids), 10000, "UUID generator produced 10000 unique identifiers");

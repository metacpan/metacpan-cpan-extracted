#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 6;

use_ok "Sys::MemInfo";

my $nbkeys = @{[Sys::MemInfo::availkeys()]};
ok(0<$nbkeys, "At least one defined key");

my $n = 0;
use Data::Dumper;
foreach my $key (Sys::MemInfo::availkeys()) {
  my $value = Sys::MemInfo::get($key);
  printf +("  Key %-20s = %7s MB = %10s kB\n", $key,
    (defined $value ? int($value/1024/1024) : "undef"),
    (defined $value ? int($value/1024) : "undef"));
  $n++;
}

ok ($n==$nbkeys, "All keys return value");

my ($tm, $fm);
ok ($tm = Sys::MemInfo::totalmem (), "Total Memory");
ok ($fm = Sys::MemInfo::freemem (),  "Free  Memory");
ok ($fm <= $tm, "Free ($fm) <= Total ($tm)");

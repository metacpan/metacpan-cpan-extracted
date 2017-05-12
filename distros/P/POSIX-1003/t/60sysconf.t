#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 10;

use POSIX::1003::Sysconf qw(sysconf %sysconf _SC_OPEN_MAX);

my $om = sysconf('_SC_OPEN_MAX');
ok(defined $om, "_SC_OPEN_MAX via function = $om");

my $om2 = _SC_OPEN_MAX;
ok(defined $om2, "_SC_OPEN_MAX directly = $om2");
cmp_ok($om, '==', $om2);

my $key = $sysconf{_SC_OPEN_MAX};
ok(defined $key, "key = $key");

my $om3;
eval { $om3 = sysconf($key) };
like($@, qr/^pass the constant name as string at/);
ok(!defined $om3);

my $om4;
eval { $om4 = sysconf(_SC_OPEN_MAX) };
like($@, qr/^pass the constant name as string at/);
ok(!defined $om4);

use POSIX::1003::Sysconf qw(sysconf_names);
my @names = sysconf_names;
cmp_ok(scalar @names, '>', 10, @names." names");
if(@names <= 10) {diag($_) for @names};   # to debug NetBSD

my $undefd = 0;
foreach my $name (sort @names)
{   my $val = sysconf($name);
    printf "  %3d  %-30s %s\n", $sysconf{$name}, $name
       , (defined $val ? $val : 'undef');
    defined $val or $undefd++;
}
ok(1, "$undefd _SC_ constants return undef");

#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 7;

use POSIX::1003::Properties qw(property %property _POSIX_VERSION);

my $nt  = property('_POSIX_VERSION');
ok(defined $nt, "_POSIX_VERSION via function = $nt");

my $nt2 = $property{_POSIX_VERSION};
ok(defined $nt2, "_POSIX_VERSION via HASH = $nt2");
cmp_ok($nt, '==', $nt2);

my $nt3 = _POSIX_VERSION;
ok(defined $nt3, "_POSIX_VERSION directly = $nt3");
cmp_ok($nt, '==', $nt3);

use POSIX::1003::Properties qw(property_names);
my @names = property_names;
cmp_ok(scalar @names, '>', 10, @names." names");

my $undefd = 0;
foreach my $name (sort @names)
{   my $val = property($name);
    printf "  %-7s %s\n", (defined $val ? $val : 'undef'), $name;
    defined $val or $undefd++;
}
ok(1, "$undefd _POSIX_ constants return undef");


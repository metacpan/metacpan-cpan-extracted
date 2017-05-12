#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 10;

use POSIX::1003::Errno qw(errno %errno EAGAIN);

my $om = errno('EAGAIN');
ok(defined $om, "EAGAIN via function = $om");

my $om2 = EAGAIN;
ok(defined $om2, "EAGAIN directly = $om2");
cmp_ok($om, '==', $om2);

my $key = $errno{EAGAIN};
ok(defined $key, "key = $key");

my $om3;
eval { $om3 = errno($key) };
like($@, qr/^pass the constant name [0-9]+ as string at/);
ok(!defined $om3);

my $om4;
eval { $om4 = errno(EAGAIN) };
like($@, qr/^pass the constant name [0-9]+ as string at/);
ok(!defined $om4);

use POSIX::1003::Errno qw(strerror errno_names);
my @names = errno_names;
cmp_ok(scalar @names, '>', 10, @names." names");

my $undefd = 0;
foreach my $name (sort @names)
{   my $val = errno($name);
    printf "  %5d  %-15s %s\n", $errno{$name}, $name
       , strerror($errno{$name});
    defined $val or $undefd++;
}
ok(1, "$undefd error constants return undef");

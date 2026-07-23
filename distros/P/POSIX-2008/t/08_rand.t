#!/usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Errno ':POSIX';
use Test::More tests => 14;

use POSIX::2008;

SKIP: {
  if (! defined &POSIX::2008::getentropy) {
    skip 'getentropy() UNAVAILABLE', 14;
  }

  if (! defined POSIX::2008::getentropy(1) && $! == ENOSYS) {
    skip 'getentropy() UNAVAILABLE', 14;
  }

  foreach my $l (~0, -273, 16361) {
    my $rv = POSIX::2008::getentropy($l);
    is($rv, undef, "getentropy($l) is undef");
    cmp_ok($!, '==', EINVAL, "getentropy($l) fails with EINVAL");
  }

  foreach my $l (0, 12, 93, 164) {
    my $rv = POSIX::2008::getentropy($l);
    isnt($rv, undef, "getentropy($l) is defined");
    cmp_ok(length("$rv"), '==', $l, "getentropy($l) has length $l");
  }
}

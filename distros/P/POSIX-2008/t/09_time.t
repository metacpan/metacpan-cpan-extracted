#!/usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Config;
use Test::More tests => 11;

use POSIX::2008;

SKIP: {
  if (! defined &POSIX::2008::strptime) {
    skip 'strptime() UNAVAILABLE', 11;
  }

  my $ts = '2037-04-30 12:34:56';
  my $fmt = '%Y-%m-%d %H:%M:%S';
  my $lts = length $ts;
  my $expected = [
    56, 34, 12, 30, 3, 137, 4, 119, undef, undef, undef
  ];

  {
    my $ts = 'foobar';
    my $rv = POSIX::2008::strptime($ts, $fmt);
    is($rv, undef, "strptime($ts, $fmt) is undef");
  }

  {
    my $n = POSIX::2008::strptime($ts, $fmt);
    cmp_ok($n, '==', $lts, "strptime($ts, $fmt) == $lts");
  }

  {
    my @tm_arg;
    my $n = POSIX::2008::strptime($ts, $fmt, \@tm_arg);
    cmp_ok($n, '==', $lts, "strptime($ts, $fmt, \@tm_arg) == $lts");
    is_deeply(\@tm_arg, $expected,
              "strptime($ts, $fmt, \@tm_arg) == $lts: check \@tm_arg");
  }

  {
    my @tm_ret = POSIX::2008::strptime($ts, $fmt);
    is_deeply(\@tm_ret, $expected, "\@tm_ret = strptime($ts, $fmt)");
  }

  {
    my @tm_arg;
    POSIX::2008::strptime($ts, $fmt, \@tm_arg);
    is_deeply(\@tm_arg, $expected, "strptime($ts, $fmt, \@tm_arg)");
  }

  {
    my @tm_arg;
    my @tm_ret = POSIX::2008::strptime($ts, $fmt, \@tm_arg);
    is_deeply(\@tm_ret, $expected,
              "\@tm_ret = strptime($ts, $fmt, \@tm_arg): check \@tm_ret");
    is_deeply(\@tm_arg, $expected,
              "\@tm_ret = strptime($ts, $fmt, \@tm_arg): check \@tm_arg");
  }

  {
    my $ts = '2037-04-30';
    my $fmt = '%Y-%m-%d';
    my $expected = [
      undef, 42, undef, 30, 3, 137, 4, 119, undef, undef, undef
    ];
    {
      my @tm_ret = POSIX::2008::strptime($ts, $fmt, undef, 42);
      is_deeply(\@tm_ret, $expected,
                "\@tm_ret = strptime($ts, $fmt, undef, 42)");
    }
    {
      my @tm_arg;
      $tm_arg[1] = 42;
      my @tm_ret = POSIX::2008::strptime($ts, $fmt, \@tm_arg);
      is_deeply(\@tm_ret, $expected,
                "\@tm_ret = strptime($ts, $fmt, \@tm_arg): check \@tm_ret");
      is_deeply(\@tm_arg, $expected,
                "\@tm_ret = strptime($ts, $fmt, \@tm_arg): check \@tm_arg");
    }
  }
}

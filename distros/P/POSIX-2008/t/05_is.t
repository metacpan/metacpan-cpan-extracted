#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 70;
use POSIX::2008;

my $ascii = join '', map chr, (0 .. 127);
my $blank = "\t ";
my $cntrl = substr $ascii, 0, 32;
my $digit = '0123456789';
my $lower = 'abcdefghijklmnopqrstuvwxyz';
my $punct = '!"#$%&\'()*+,-./:;<=>?@[\]^_`{|}~)';
my $space = join '', map chr, (9 .. 13), 32;
my $upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
my $xdigit = '0123456789ABCDEFabcdef';
my $alpha = "${upper}${lower}";
my $alnum = "${alpha}${digit}";
my $graph = "${alnum}${punct}";
my $print = " ${graph}";

my $inf_ok = do {
  use bigrat;
  sprintf('%f', inf()) =~ /^inf$/i;
};
my $nan_ok = do {
  use bigrat;
  sprintf('%f', NaN()) =~ /^nan$/i;
};

SKIP: {
  if (!defined &POSIX::2008::isatty) {
    skip 'isatty() UNAVAILABLE', 1;
  }
  ok(!(POSIX::2008::isatty(\*STDOUT) xor -t \*STDOUT), 'isatty(STDOUT)');
}

SKIP: {
  if (!defined &POSIX::2008::isfinite) {
    skip 'isfinite() UNAVAILABLE', 4;
  }
  else {
    ok(POSIX::2008::isfinite(0), 'isfinite(0)');
    if (!$inf_ok || !$nan_ok) {
      skip 'inf() or NaN() broken', 3;
    }
    else {
      use bigrat;
      ok(!$nan_ok || !POSIX::2008::isfinite(NaN()), '!isfinite(NaN)');
      ok(!$inf_ok || !POSIX::2008::isfinite(inf()), '!isfinite(inf)');
      ok(!$inf_ok || !POSIX::2008::isfinite(-inf()), '!isfinite(-inf)');
    }
  }
}

SKIP: {
  if (!defined &POSIX::2008::isinf) {
    skip 'isinf() UNAVAILABLE', 4;
  }
  else {
    ok(!POSIX::2008::isinf(0), '!isinf(0)');
    if (!$inf_ok || !$nan_ok) {
      skip 'inf() or NaN() broken', 3;
    }
    else {
      use bigrat;
      ok(!$nan_ok || !POSIX::2008::isinf(NaN()), '!isinf(NaN)');
      ok(!$inf_ok || POSIX::2008::isinf(inf()), 'isinf(inf)');
      ok(!$inf_ok || POSIX::2008::isinf(-inf()), 'isinf(-inf)');
    }
  }
}

SKIP: {
  if (!defined &POSIX::2008::isnan) {
    skip 'isnan() UNAVAILABLE', 4;
  }
  else {
    ok(!POSIX::2008::isnan(0), '!isnan(0)');
    if (!$inf_ok || !$nan_ok) {
      skip 'inf() or NaN() broken', 3;
    }
    else {
      use bigrat;
      ok(!$nan_ok || POSIX::2008::isnan(NaN()), 'isnan(NaN)');
      ok(!$inf_ok || !POSIX::2008::isnan(inf()), '!isnan(inf)');
      ok(!$inf_ok || !POSIX::2008::isnan(-inf()), '!isnan(-inf)');
    }
  }
}

SKIP: {
  if (!defined &POSIX::2008::isnormal) {
    skip 'isnormal() UNAVAILABLE', 5;
  }
  else {
    ok(POSIX::2008::isnormal(1), 'isnormal(1)');
    ok(!POSIX::2008::isnormal(0), '!isnormal(0)');
    if (!$inf_ok || !$nan_ok) {
      skip 'inf() or NaN() broken', 3;
    }
    else {
      use bigrat;
      ok(!$nan_ok || !POSIX::2008::isnormal(NaN()), '!isnormal(NaN)');
      ok(!$inf_ok || !POSIX::2008::isnormal(inf()), '!isnormal(inf)');
      ok(!$inf_ok || !POSIX::2008::isnormal(-inf()), '!isnormal(-inf)');
    }
  }
}

SKIP: {
  if (!defined &POSIX::2008::isalnum) {
    skip 'isalnum() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::isalnum($alnum), 'isalnum(alnum)');
  ok(!POSIX::2008::isalnum("$alnum$space"), '!isalnum(alnum+space)');
  ok(!POSIX::2008::isalnum(''), "!isalnum('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::isalnum(undef), 'isalnum(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::isalpha) {
    skip 'isalpha() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::isalpha($alpha), 'isalpha(alpha)');
  ok(!POSIX::2008::isalpha("$alpha$space"), '!isalpha(alpha+space)');
  ok(!POSIX::2008::isalpha(''), "!isalpha('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::isalpha(undef), 'isalpha(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::isascii) {
    skip 'isascii() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::isascii($ascii), 'isascii(ascii)');
  ok(!POSIX::2008::isascii("$ascii\x80"), '!isascii(ascii+0x80)');
  ok(!POSIX::2008::isascii(''), "!isascii('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::isascii(undef), 'isascii(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::isblank) {
    skip 'isblank() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::isblank($blank), 'isblank(blank)');
  ok(!POSIX::2008::isblank("$blank$digit"), '!isblank(blank+digit)');
  ok(!POSIX::2008::isblank(''), "!isblank('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::isblank(undef), 'isblank(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::iscntrl) {
    skip 'iscntrl() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::iscntrl($cntrl), 'iscntrl(cntrl)');
  ok(!POSIX::2008::iscntrl("$cntrl$digit"), '!iscntrl(cntrl+digit)');
  ok(!POSIX::2008::iscntrl(''), "!iscntrl('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::iscntrl(undef), 'iscntrl(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::isdigit) {
    skip 'isdigit() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::isdigit($digit), 'isdigit(digit)');
  ok(!POSIX::2008::isdigit("$digit$space"), '!isdigit(digit+space)');
  ok(!POSIX::2008::isdigit(''), "!isdigit('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::isdigit(undef), 'isdigit(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::isgraph) {
    skip 'isgraph() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::isgraph($graph), 'isgraph(graph)');
  ok(!POSIX::2008::isgraph("$graph$space"), '!isgraph(graph+space)');
  ok(!POSIX::2008::isgraph(''), "!isgraph('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::isgraph(undef), 'isgraph(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::islower) {
    skip 'islower() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::islower($lower), 'islower(lower)');
  ok(!POSIX::2008::islower("$lower$upper"), '!islower(lower+upper)');
  ok(!POSIX::2008::islower(''), "!islower('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::islower(undef), 'islower(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::isprint) {
    skip 'isprint() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::isprint($print), 'isprint(print)');
  ok(!POSIX::2008::isprint("$print$space"), '!isprint(print+space)');
  ok(!POSIX::2008::isprint(''), "!isprint('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::isprint(undef), 'isprint(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::ispunct) {
    skip 'ispunct() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::ispunct($punct), 'ispunct(punct)');
  ok(!POSIX::2008::ispunct("$punct$space"), '!ispunct(punct+space)');
  ok(!POSIX::2008::ispunct(''), "!ispunct('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::ispunct(undef), 'ispunct(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::isspace) {
    skip 'isspace() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::isspace($space), 'isspace(space)');
  ok(!POSIX::2008::isspace("$space$cntrl"), '!isspace(space+cntrl)');
  ok(!POSIX::2008::isspace(''), "!isspace('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::isspace(undef), 'isspace(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::isupper) {
    skip 'isupper() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::isupper($upper), 'isupper(upper)');
  ok(!POSIX::2008::isupper("$upper$lower"), '!isupper(upper+lower)');
  ok(!POSIX::2008::isupper(''), "!isupper('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::isupper(undef), 'isupper(undef)');
}

SKIP: {
  if (!defined &POSIX::2008::isxdigit) {
    skip 'isxdigit() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::isxdigit($xdigit), 'isxdigit(xdigit)');
  ok(!POSIX::2008::isxdigit("$xdigit$alpha"), '!isxdigit(xdigit+alpha)');
  ok(!POSIX::2008::isxdigit(''), "!isxdigit('')");
  no warnings 'uninitialized';
  ok(!POSIX::2008::isxdigit(undef), 'isxdigit(undef)');
}

#!/usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Config;
use Test::More tests => 43;

use POSIX::2008;

sub _cmp_between {
  my ($lower, $value, $upper, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  cmp_ok($lower, '<', $value, $desc);
  cmp_ok($value, '<', $upper, $desc);
}

# is_deeply() fails to compare 0.0 == -0.0
sub _cmp_cmplx {
  my ($got, $expected, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  cmp_ok($got->[0], '==', $expected->[0], $desc);
  cmp_ok($got->[1], '==', $expected->[1], $desc);
}

SKIP: {
  if (! defined &POSIX::2008::cabs) { skip 'cabs() UNAVAILABLE', 1; }
  cmp_ok(POSIX::2008::cabs(3.0, 4.0), '==', 5.0, 'cabs(3, 4) == 5');
}

SKIP: {
  if (! defined &POSIX::2008::carg) { skip 'carg() UNAVAILABLE', 2; }
  _cmp_between(0.927295, POSIX::2008::carg(3.0, 4.0), 0.927296, 'carg(3, 4)');
}

SKIP: {
  if (! defined &POSIX::2008::cimag) { skip 'cimag() UNAVAILABLE', 1; }
  cmp_ok(POSIX::2008::cimag(3.0, 4.0), '==', 4.0, 'cimag(3, 4) == 4');
}

SKIP: {
  if (! defined &POSIX::2008::cproj) { skip 'cproj() UNAVAILABLE', 2; }
  if (my $glibcv = $Config{gnulibc_version}) {
    my @v = split /\./, $glibcv;
    if ($v[0] < 2 || $v[0] == 2 && $v[1] < 12) {
      skip 'cproj() broken in glibc < 2.12', 2;
    }
  }
  _cmp_cmplx([POSIX::2008::cproj(3.0, 4.0)], [3.0, 4.0], 'cproj(3, 4) == (3, 4)');
}

SKIP: {
  if (! defined &POSIX::2008::creal) { skip 'creal() UNAVAILABLE', 1; }
  cmp_ok(POSIX::2008::creal(3.0, 4.0), '==', 3.0, 'creal(3, 4) == 3');
}

SKIP: {
  if (! defined &POSIX::2008::cexp) { skip 'cexp() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::cexp(0.0, 0.0)], [1.0, 0.0], 'cexp(0, 0) == (1, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::clog) { skip 'clog() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::clog(1.0, 0.0)], [0.0, 0.0], 'clog(1, 0) == (0, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::conj) { skip 'conj() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::conj(3.0, 4.0)], [3.0, -4.0], 'conj(3, 4) == (3, -4)');
}

SKIP: {
  if (! defined &POSIX::2008::cpow) { skip 'cpow() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::cpow(1.0, 2.0, 0.0, 0.0)], [1.0, 0.0], 'cpow(1, 2, 0, 0) == (1, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::csqrt) { skip 'csqrt() UNAVAILABLE', 4; }
  _cmp_cmplx([POSIX::2008::csqrt(9.0, 0.0)], [3.0, 0.0], 'csqrt(9, 0) == (3, 0)');
  _cmp_cmplx([POSIX::2008::csqrt(-9.0, 0.0)], [0.0, 3.0], 'csqrt(-9, 0) == (0, 3)');
} 

SKIP: {
  if (! defined &POSIX::2008::cacos) { skip 'cacos() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::cacos(1.0, 0.0)], [0.0, 0.0], 'cacos(1, 0) == (0, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::cacosh) { skip 'cacosh() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::cacosh(1.0, 0.0)], [0.0, 0.0], 'cacosh(1, 0) == (0, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::casin) { skip 'casin() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::casin(0.0, 0.0)], [0.0, 0.0], 'casin(0, 0) == (0, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::casinh) { skip 'casinh() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::casinh(0.0, 0.0)], [0.0, 0.0], 'casinh(0, 0) == (0, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::catan) { skip 'catan() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::catan(0.0, 0.0)], [0.0, 0.0], 'catan(0, 0) == (0, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::catanh) { skip 'catanh() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::catanh(0.0, 0.0)], [0.0, 0.0], 'catanh(0, 0) == (0, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::ccos) { skip 'ccos() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::ccos(0.0, 0.0)], [1.0, 0.0], 'ccos(0, 0) == (1, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::ccosh) { skip 'ccosh() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::ccosh(0.0, 0.0)], [1.0, 0.0], 'ccosh(0, 0) == (1, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::csin) { skip 'csin() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::csin(0.0, 0.0)], [0.0, 0.0], 'csin(0, 0) == (0, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::csinh) { skip 'csinh() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::csinh(0.0, 0.0)], [0.0, 0.0], 'csinh(0, 0) == (0, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::ctan) { skip 'ctan() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::ctan(0.0, 0.0)], [0.0, 0.0], 'ctan(0, 0) == (0, 0)');
}

SKIP: {
  if (! defined &POSIX::2008::ctanh) { skip 'ctanh() UNAVAILABLE', 2; }
  _cmp_cmplx([POSIX::2008::ctanh(0.0, 0.0)], [0.0, 0.0], 'ctanh(0, 0) == (0, 0)');
}

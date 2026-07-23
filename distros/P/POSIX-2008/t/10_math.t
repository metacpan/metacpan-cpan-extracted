#!/usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Test::More tests => 157;

use POSIX::2008;

sub _cmp_between {
  my ($lower, $value, $upper, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  cmp_ok($lower, '<', $value, $desc);
  cmp_ok($value, '<', $upper, $desc);
}

SKIP: {
  if (! defined &POSIX::2008::acos) { skip 'acos() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::acos(1.0), '==', 0.0, 'acos(1) == 0');
  _cmp_between(1.047197, POSIX::2008::acos(.5), 1.047198, 'acos(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::acosh) { skip 'acosh() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::acosh(1.0), '==', 0.0, 'acosh(1) == 0');
  _cmp_between(2.292431, POSIX::2008::acosh(5.0), 2.292432, 'acosh(5)');
}

SKIP: {
  if (! defined &POSIX::2008::asin) { skip 'asin() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::asin(0.0), '==', 0.0, 'asin(0) == 0');
  cmp_ok(POSIX::2008::asin(-.75), '==', -POSIX::2008::asin(.75), 'asin(-x) == -asin(x)');
  _cmp_between(0.523598, POSIX::2008::asin(.5), 0.523599, 'asin(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::asinh) { skip 'asinh() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::asinh(0.0), '==', 0.0, 'asinh(0) == 0');
  cmp_ok(POSIX::2008::asinh(-.75), '==', -POSIX::2008::asinh(.75), 'asinh(-x) == -asinh(x)');
  _cmp_between(0.481211, POSIX::2008::asinh(.5), 0.481212, 'asinh(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::atan) { skip 'atan() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::atan(0.0), '==', 0.0, 'atan(0) == 0');
  cmp_ok(POSIX::2008::atan(-.5), '==', -POSIX::2008::atan(.5), 'atan(-x) == -atan(x)');
  _cmp_between(0.463647, POSIX::2008::atan(.5), 0.463648, 'atan(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::atanh) { skip 'atanh() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::atanh(0.0), '==', 0.0, 'atanh(0) == 0');
  cmp_ok(POSIX::2008::atanh(-.75), '==', -POSIX::2008::atanh(.75), 'atanh(-x) == -atanh(x)');
  _cmp_between(0.549306, POSIX::2008::atanh(.5), 0.549307, 'atanh(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::atan2) { skip 'atan2() UNAVAILABLE', 5; }
  cmp_ok(POSIX::2008::atan2(0.0, 1.0), '==', 0.0, 'atan2(0, 1) == 0');
  cmp_ok(POSIX::2008::atan2(-3.0, 4.0), '==', -POSIX::2008::atan2(3.0, 4.0), 'atan2(-y, x) == -atan2(y, x)');
  cmp_ok(POSIX::2008::atan2(1.0, 2.0), '==', POSIX::2008::atan(.5), 'atan2(1, 2) == atan(.5)');
  _cmp_between(0.463647, POSIX::2008::atan2(1.0, 2.0), 0.463648, 'atan2(1, 2)');
}

SKIP: {
 if (! defined &POSIX::2008::cbrt) { skip 'cbrt() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::cbrt(8.0), '==', 2.0, 'cbrt(8) == 2');
  _cmp_between(0.793700, POSIX::2008::cbrt(.5), 0.793701, 'cbrt(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::ceil) { skip 'ceil() UNAVAILABLE', 1; }
  cmp_ok(POSIX::2008::ceil(3.141592653), '==', 4.0, 'ceil(pi) == 4');
}

SKIP: {
  if (! defined &POSIX::2008::cos) { skip 'cos() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::cos(0.0), '==', 1.0, 'cos(0) == 1');
  cmp_ok(POSIX::2008::cos(-.75), '==', POSIX::2008::cos(0.75), 'cos(-x) == cos(x)');
  _cmp_between(0.877582, POSIX::2008::cos(.5), 0.877583, 'cos(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::cosh) { skip 'cosh() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::cosh(0.0), '==', 1.0, 'cosh(0) == 1');
  cmp_ok(POSIX::2008::cosh(-.75), '==', POSIX::2008::cosh(0.75), 'cosh(-x) == cosh(x)');
  _cmp_between(1.127625, POSIX::2008::cosh(.5), 1.127626, 'cosh(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::erf) { skip 'erf() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::erf(0.0), '==', 0.0, 'erf(0) == 0');
  cmp_ok(POSIX::2008::erf(-.75), '==', -POSIX::2008::erf(0.75), 'erf(-x) == -erf(x)');
  _cmp_between(0.520499, POSIX::2008::erf(.5), 0.520500, 'erf(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::erfc) { skip 'erfc() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::erfc(0.0), '==', 1.0, 'erfc(0) == 1');
  _cmp_between(0.479500, POSIX::2008::erfc(.5), 0.479501, 'erfc(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::exp) { skip 'exp() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::exp(0.0), '==', 1.0, 'exp(0) == 1');
  _cmp_between(1.648721, POSIX::2008::exp(.5), 1.648722, 'exp(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::exp2) { skip 'exp2() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::exp2(0.0), '==', 1.0, 'exp2(0) == 1');
  cmp_ok(POSIX::2008::exp2(1.0), '==', 2.0, 'exp2(1) == 2');
  _cmp_between(1.414213, POSIX::2008::exp2(.5), 1.414214, 'exp2(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::expm1) { skip 'expm1() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::expm1(0.0), '==', 0.0, 'expm1(0) == 0');
  _cmp_between(0.648721, POSIX::2008::expm1(.5), 0.648722, 'expm1(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::fabs) { skip 'fabs() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::fabs(0.0), '==', 0.0, 'fabs(0) == 0');
  cmp_ok(POSIX::2008::fabs(-0.2), '==', POSIX::2008::fabs(0.2), 'fabs(-.2) == fabs(.2)');
  cmp_ok(POSIX::2008::fabs(-0.5), '==', 0.5, 'fabs(-.5) == .5');
}

SKIP: {
  if (! defined &POSIX::2008::fdim) { skip 'fdim() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::fdim(73., 37.), '==', 36., 'fdim(73, 37) == 36');
  cmp_ok(POSIX::2008::fdim(37., 73.), '==',  0., 'fdim(37, 73) == 0');
}

SKIP: {
  if (! defined &POSIX::2008::floor) { skip 'floor() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::floor(3.141592653), '==', 3.0, 'floor(pi) == 3');
  cmp_ok(POSIX::2008::floor(-3.141592653), '==', -4.0, 'floor(-pi) == -4');
}

SKIP: {
  if (! defined &POSIX::2008::fma) { skip 'fma() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::fma(2.,  3., 4.), '==', 10., 'fma(2, 3, 4) == 10');
  cmp_ok(POSIX::2008::fma(2., -3., 4.), '==', -2., 'fma(2, -3, 4) == -2');
}

SKIP: {
  if (! defined &POSIX::2008::fmax) { skip 'fmax() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::fmax(73., 37.), '==', 73., 'fmax(73, 37) == 73');
  cmp_ok(POSIX::2008::fmax(-42., -21.), '==', -21., 'fmax(-42, -21) == -21');
}

SKIP: {
  if (! defined &POSIX::2008::fmin) { skip 'fmin() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::fmin(73., 37.), '==', 37., 'fmin(73, 37) == 37');
  cmp_ok(POSIX::2008::fmin(-42., -21.), '==', -42., 'fmin(-42, -21) == -42');
}

SKIP: {
  if (! defined &POSIX::2008::fmod) { skip 'fmod() UNAVAILABLE', 1; }
  cmp_ok(POSIX::2008::fmod(4.0, 1.75), '==', 0.5, 'fmod(4, 1.75) == 0.5');
}

SKIP: {
  if (! defined &POSIX::2008::frexp) { skip 'frexp() UNAVAILABLE', 1; }
  is_deeply([POSIX::2008::frexp(2.5)], [0.625, 2], 'frexp(2.5) == (0.625, 2)');
}

SKIP: {
  if (! defined &POSIX::2008::hypot) { skip 'hypot() UNAVAILABLE', 1; }
  cmp_ok(POSIX::2008::hypot(3.0, 4.0), '==', 5.0, 'hypot(3, 4) == 5');
}

SKIP: {
  if (! defined &POSIX::2008::ilogb) { skip 'ilogb() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::ilogb(1023.), '==', 9, 'ilogb(1023) == 9');
  cmp_ok(POSIX::2008::ilogb(1024.), '==', 10, 'ilogb(1024) == 10');
}

SKIP: {
  if (! defined &POSIX::2008::j0) { skip 'j0() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::j0(0.), '==', 1., 'j0(0) == 1');
  _cmp_between(0.765197, POSIX::2008::j0(1.), 0.765198, 'j0(1)');
}

SKIP: {
  if (! defined &POSIX::2008::j1) { skip 'j1() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::j1(0.), '==', 0., 'j1(0) == 0');
  _cmp_between(0.440050, POSIX::2008::j1(1.), 0.440051, 'j1(1)');
}

SKIP: {
  if (! defined &POSIX::2008::jn) { skip 'jn() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::jn(0, 1.), '==', POSIX::2008::j0(1.), 'jn(0, 1) == j0(1)');
  cmp_ok(POSIX::2008::jn(1, 1.), '==', POSIX::2008::j1(1.), 'jn(1, 1) == j1(1)');
  _cmp_between(0.114903, POSIX::2008::jn(2, 1.), 0.114904, 'jn(2, 1)');
}

SKIP: {
  if (! defined &POSIX::2008::ldexp) { skip 'ldexp() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::ldexp(3., 0), '==', 3., 'ldexp(3, 0) == 3');
  cmp_ok(POSIX::2008::ldexp(3., 4), '==', 48., 'ldexp(3, 4) == 48');
}

SKIP: {
  if (! defined &POSIX::2008::lgamma) { skip 'lgamma() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::lgamma(1.), '==', 0., 'lgamma(1) == 0');
  cmp_ok(POSIX::2008::lgamma(2.), '==', 0., 'lgamma(2) == 0');
}

SKIP: {
  if (! defined &POSIX::2008::log) { skip 'log() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::log(1.), '==', 0., 'log(1) == 0');
  _cmp_between(1.098612, POSIX::2008::log(3.), 1.098613, 'log(3)');
}

SKIP: {
  if (! defined &POSIX::2008::log10) { skip 'log10() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::log10(1.), '==', 0., 'log10(1) == 0');
  _cmp_between(0.477121, POSIX::2008::log10(3.), 0.477122, 'log10(3)');
}

SKIP: {
  if (! defined &POSIX::2008::log1p) { skip 'log1p() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::log1p(0.), '==', 0., 'log1p(0) == 0');
  _cmp_between(1.098612, POSIX::2008::log1p(2.), 1.098613, 'log1p(3)');
}

SKIP: {
  if (! defined &POSIX::2008::log2) { skip 'log2() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::log2(1.), '==', 0., 'log2(1) == 0');
  _cmp_between(1.584962, POSIX::2008::log2(3.), 1.584963, 'log2(3)');
}

SKIP: {
  if (! defined &POSIX::2008::logb) { skip 'logb() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::logb(1023.), '==', 9., 'logb(1023) == 9');
  cmp_ok(POSIX::2008::logb(1024.), '==', 10., 'logb(1024) == 10');
}

SKIP: {
  if (! defined &POSIX::2008::lrint) { skip 'lrint() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::lrint(.8), '==', 1., 'lrint(.8) == 1');
  cmp_ok(POSIX::2008::lrint(1.2), '==', 1., 'lrint(1.2) == 1');
}

SKIP: {
  if (! defined &POSIX::2008::lround) { skip 'lround() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::lround(.8), '==', 1, 'lround(.8) == 1');
  cmp_ok(POSIX::2008::lround(1.2), '==', 1, 'lround(1.2) == 1');
}

SKIP: {
  if (! defined &POSIX::2008::nearbyint) { skip 'nearbyint() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::nearbyint(.8), '==', 1., 'nearbyint(.8) == 1');
  cmp_ok(POSIX::2008::nearbyint(1.2), '==', 1., 'nearbyint(1.2) == 1');
}

SKIP: {
  if (! defined &POSIX::2008::nextafter) { skip 'nextafter() UNAVAILABLE', 4; }
  _cmp_between(1.0, POSIX::2008::nextafter(1., 2.), 1.1, 'nextafter(1, 2)');
  _cmp_between(0.9, POSIX::2008::nextafter(1., 0.), 1.0, 'nextafter(1, 2)');
}

SKIP: {
  if (! defined &POSIX::2008::nexttoward) { skip 'nexttoward() UNAVAILABLE', 4; }
  _cmp_between(1.0, POSIX::2008::nexttoward(1., 2.), 1.1, 'nexttoward(1, 2)');
  _cmp_between(0.9, POSIX::2008::nexttoward(1., 0.), 1.0, 'nexttoward(1, 2)');
}

SKIP: {
  if (! defined &POSIX::2008::pow) { skip 'pow() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::pow(0., 1.2), '==', 0., 'pow(0, 1.2) == 0');
  cmp_ok(POSIX::2008::pow(1.2, 0.), '==', 1., 'pow(1.2, 0) == 1');
  _cmp_between(1.157031, POSIX::2008::pow(1.2, 0.8), 1.157032, 'pow(1.2, 0.8)');
}

SKIP: {
  if (! defined &POSIX::2008::remainder) { skip 'remainder() UNAVAILABLE', 1; }
  cmp_ok(POSIX::2008::remainder(4.0, 1.75), '==', 0.5, 'remainder(4, 1.75) == 0.5');
}

SKIP: {
  if (! defined &POSIX::2008::rint) { skip 'rint() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::rint(.8), '==', 1., 'rint(.8) == 1');
  cmp_ok(POSIX::2008::rint(1.2), '==', 1., 'rint(1.2) == 1');
}

SKIP: {
  if (! defined &POSIX::2008::round) { skip 'round() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::round(.8), '==', 1., 'round(.8) == 1');
  cmp_ok(POSIX::2008::round(1.2), '==', 1., 'round(1.2) == 1');
}

SKIP: {
  if (! defined &POSIX::2008::sin) { skip 'sin() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::sin(0.0), '==', 0.0, 'sin(0) == 0');
  cmp_ok(POSIX::2008::sin(-.75), '==', -POSIX::2008::sin(.75), 'sin(-x) == -sin(x)');
  _cmp_between(0.479425, POSIX::2008::sin(.5), 0.479426, 'sin(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::sinh) { skip 'sinh() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::sinh(0.0), '==', 0.0, 'sinh(0) == 0');
  cmp_ok(POSIX::2008::sinh(-.75), '==', -POSIX::2008::sinh(.75), 'sinh(-x) == -sinh(x)');
  _cmp_between(0.521095, POSIX::2008::sinh(.5), 0.521096, 'sinh(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::sqrt) { skip 'sqrt() UNAVAILABLE', 3; }
  cmp_ok(POSIX::2008::sqrt(9.0), '==', 3.0, 'sqrt(9) == 3');
  _cmp_between(0.707106, POSIX::2008::sqrt(.5), 0.707107, 'sqrt(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::tan) { skip 'tan() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::tan(0.0), '==', 0.0, 'tan(0) == 0');
  cmp_ok(POSIX::2008::tan(-.75), '==', -POSIX::2008::tan(.75), 'tan(-x) == -tan(x)');
  _cmp_between(0.546302, POSIX::2008::tan(.5), 0.546303, 'tan(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::tanh) { skip 'tanh() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::tanh(0.0), '==', 0.0, 'tanh(0) == 0');
  cmp_ok(POSIX::2008::tanh(-.75), '==', -POSIX::2008::tanh(.75), 'tanh(-x) == -tanh(x)');
  _cmp_between(0.462117, POSIX::2008::tanh(.5), 0.462118, 'tanh(.5)');
}

SKIP: {
  if (! defined &POSIX::2008::tgamma) { skip 'tgamma() UNAVAILABLE', 3; }
  _cmp_between(1.225416, POSIX::2008::tgamma(.75), 1.225417, 'tgamma(3/4)');
  cmp_ok(POSIX::2008::tgamma(4.), '==', 6., 'tgamma(4) == 6');
}

SKIP: {
  if (! defined &POSIX::2008::trunc) { skip 'trunc() UNAVAILABLE', 2; }
  cmp_ok(POSIX::2008::trunc(3.141592653), '==', 3.0, 'trunc(pi) == 3');
  cmp_ok(POSIX::2008::trunc(-3.141592653), '==', -3.0, 'trunc(-pi) == -3');
}

SKIP: {
  if (! defined &POSIX::2008::y0) { skip 'y0() UNAVAILABLE', 2; }
  _cmp_between(-0.444519, POSIX::2008::y0(0.5), -0.444518, 'y0(0.5)');
}

SKIP: {
  if (! defined &POSIX::2008::y1) { skip 'y1() UNAVAILABLE', 2; }
  _cmp_between(-1.471473, POSIX::2008::y1(0.5), -1.471472, 'y1(0.5)');
}

SKIP: {
  if (! defined &POSIX::2008::yn) { skip 'yn() UNAVAILABLE', 4; }
  cmp_ok(POSIX::2008::yn(0, .5), '==', POSIX::2008::y0(.5), 'yn(0, .5) == y0(.5)');
  cmp_ok(POSIX::2008::yn(1, .5), '==', POSIX::2008::y1(.5), 'yn(1, .5) == y1(.5)');
  _cmp_between(-5.441371, POSIX::2008::yn(2, .5), -5.441370, 'yn(2, .5)');
}

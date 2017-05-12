#!perl -T

use strict;
use warnings;

use Test::More tests => 30;

# script for testing the internal sub &_parse_args()

use_ok('Number::Bytes::Human');

*_parse_args = \&Number::Bytes::Human::_parse_args;

## options to set BLOCK

is_deeply(
  _parse_args({}, { block => 1024 }),
  { BLOCK => 1024 });

is_deeply(
  _parse_args({}, { block_size => 1024 }),
  { BLOCK => 1024 });

is_deeply(
  _parse_args({}, { base => 1024 }),
  { BLOCK => 1024 });

is_deeply(
  _parse_args({}, { bs => 1024 }),
  { BLOCK => 1024 });

is_deeply(
  _parse_args({}, { block_1024 => 1 }),
  { BLOCK => 1024 });

is_deeply(
  _parse_args({}, { base_1024 => 1 }),
  { BLOCK => 1024 });

is_deeply(
  _parse_args({}, { 1024 => 1 }),
  { BLOCK => 1024 });

is_deeply(
  _parse_args({}, { block_1000 => 1 }),
  { BLOCK => 1000 });

is_deeply(
  _parse_args({}, { base_1000 => 1 }),
  { BLOCK => 1000 });

is_deeply(
  _parse_args({}, { 1000 => 1 }),
  { BLOCK => 1000 });

is_deeply(
  _parse_args({}, { bs => 1024000 }),
  { BLOCK => 1_024_000 });

# block + block_size
is_deeply(
  _parse_args({}, { block => 1024, block_size => 1000 }),
  { BLOCK => 1024 }, "block has precedence over block_size");

# block + block_1000
is_deeply(
  _parse_args({}, { block => 1024, block_1000 => 1 }),
  { BLOCK => 1024 }, "block has precedence over block_1000");

eval {
  my $ans = _parse_args({}, { block => 1010 });
  fail('block => 1010 should be bad');
};
like($@, qr/^invalid base/) if $@;

## options to set ROUND_*

my $ans;

my $dummy = sub { 'dummy' };
is_deeply(
  _parse_args({}, { round_function => $dummy }),
  { ROUND_FUNCTION => $dummy, ROUND_STYLE => 'unknown' });

is_deeply(
  _parse_args({}, { round_function => $dummy, round_style => 'dummy' }),
  { ROUND_FUNCTION => $dummy, ROUND_STYLE => 'dummy' });

$ans = _parse_args({}, { round_style => 'ceil' });
isa_ok($ans->{ROUND_FUNCTION}, 'CODE');
delete $ans->{ROUND_FUNCTION};
is_deeply($ans, { ROUND_STYLE => 'ceil' });

$ans = _parse_args({}, { round_style => 'floor' });
isa_ok($ans->{ROUND_FUNCTION}, 'CODE');
delete $ans->{ROUND_FUNCTION};
is_deeply($ans, { ROUND_STYLE => 'floor' });

eval {
  my $ans = _parse_args({}, { round_function => 1 });
  fail('round_function => 1 should be bad');
};
like($@, qr/^round function (.*) should be a code ref/, 'round_function => 1 is bad') if $@;

eval {
  my $ans = _parse_args({}, { round_function => {} });
  fail('round_function => {} should be bad');
};
like($@, qr/^round function (.*) should be a code ref/, 'round_function => {} is bad') if $@;

## OPTION SUFFIXES

my $suff = [];
is_deeply(
  _parse_args({}, { suffixes => $suff }),
  { SUFFIXES => $suff }, "suffixes => [] works");

## OPTION si
is_deeply(
  _parse_args({}, { si => 1, bs => 1000 }),
  { SI => 1, BLOCK => 1000 }, "si => 1, bs => 1000 works");

is_deeply(
  _parse_args({}, { si => 1, bs => 1024 }),
  { SI => 1, BLOCK => 1024 }, "si => 1, bs => 1024 works");

## option ZERO

is_deeply(
  _parse_args({}, { zero => '-' }),
  { ZERO => '-' }, "zero => '-' works");

is_deeply(
  _parse_args({ SUFFIXES => [ 'X' ]}, { zero => '0%S' }),
  { ZERO => '0X', SUFFIXES => [ 'X' ] },
  "zero => '0%S' works");

## option PRECISION

is_deeply(
  _parse_args({}, { precision => '2' }),
  { PRECISION => '2' }, "precision => '2' works");

## option PRECISION_CUTOFF

is_deeply(
  _parse_args({}, { precision_cutoff => '-1' }),
  { PRECISION_CUTOFF => '-1' }, "precision_cutoff => '-1' works");

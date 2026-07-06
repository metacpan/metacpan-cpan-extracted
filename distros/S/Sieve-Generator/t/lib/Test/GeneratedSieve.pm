use v5.36.0;
package Test::GeneratedSieve;

use Test2::API qw/context/;
use Test::Differences;
unified_diff;

use Sub::Exporter -setup => [ qw( sieve_is element_eq ) ];

sub element_eq ($got, $expected, $desc) {
  my $ctx = context();

  my $got_sieve = $got->as_sieve;
  my $exp_sieve = $expected->as_sieve;
  chomp $got_sieve;
  chomp $exp_sieve;

  my $bool = eq_or_diff(
    $got_sieve,
    $exp_sieve,
    $desc,
  );

  $ctx->release;
  return $bool;
}

sub sieve_is ($sieve, $expect, $desc) {
  my $ctx = context();

  my $got = $sieve->as_sieve;
  chomp $got;
  chomp $expect;

  my $bool = eq_or_diff(
    $got,
    $expect,
    $desc,
  );

  $ctx->release;
  return $bool;
}

1;

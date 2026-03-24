use v5.36.0;
package Test::GeneratedSieve;

use Test2::API qw/context/;
use Test::Differences;
unified_diff;

use Sub::Exporter -setup => [ qw( sieve_is ) ];

sub sieve_is ($sieve, $expect, $desc) {
  my $ctx = context();

  my $bool = eq_or_diff(
    $sieve->as_sieve,
    $expect,
    $desc,
  );

  $ctx->release;
  return $bool;
}

1;

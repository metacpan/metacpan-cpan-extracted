use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'Termbox::PP::Terminfo::Builtin', qw(
    @terminfo_cap_indexes
    %builtin_terms
    @builtin_terms_orders
  );
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :return );
}

BEGIN {
  # Set TERM to a default value on Windows if not set
  $ENV{TERM} //= 'xterm-256color' if $^O eq 'MSWin32';
}

my $expected_count = scalar @terminfo_cap_indexes;

for my $name (@builtin_terms_orders) {
  ok(
    exists $builtin_terms{$name},
    "$name is present in \%builtin_terms"
  );
  my $term = $builtin_terms{$name};
  is(
    scalar(@$term),
    $expected_count,
    "$name has $expected_count terminfo entries"
  );
}

SKIP: {
  skip 'TERM not set', 3 unless $ENV{TERM};
  my $rv = Termbox::load_builtin_caps();
  is($rv, TB_OK(), 'load_builtin_caps() returns TB_OK');
}

done_testing;

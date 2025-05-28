#!perl

use strict;
use warnings;
use Test::More tests => 38;
use Net::CIDR::Set;

# These tests are meant to exercise the _is_cidr() function.
#
# as_string -> as_range_array -> iterate_ranges -> decode -> _is_cidr

{
  # 18 tests
  my @input = (
    "194.79.0.0-194.79.1.255",
    "194.79.0.0-194.79.1.254",
    "194.79.0.1-194.79.1.255",
    "85.63.41.0-85.63.41.15",
    "85.63.41.0-85.63.41.13",
    "85.63.41.2-85.63.41.13",
    "85.63.41.2-85.63.41.15",
    '2001:0db8:1234::/48',
    '2001:0db8:1234::/48, 2001:0db8:1235::/48',
    '2001:0db8:1235::/48, 2001:0db8:1236::/48',
    '2001:0db8:1234::-2001:0db8:1234:ffff::',
    '2001:0db8:1234::-2001:0db8:1235:ffff::',
    '2001:0db8:1235::-2001:0db8:1236:ffff::',
    '2001:0db8:1234::-2001:0db8:1235::',
    "60.200.0.0/24, 60.200.1.0/24, 60.200.2.0/24, 60.200.3.0/24",
    "60.200.0.0/24, 60.200.1.0/24, 60.200.2.0/24",
    "60.200.0.0/24, 60.200.2.0/24",
    "60.200.0.0/24, 60.200.1.0/25",
  );
  # 16 more tests
  for my $i (0..7) {
    my $j = $i + 1;
    push @input, "60.200.$i.0/24, 60.200.$j.0/24";
    push @input, "60:200:${i}::/48, 60:200:${j}::/48";
  }
  for my $orig_string (@input) {
    my $set = Net::CIDR::Set->new($orig_string);
    my $new_string = $set->as_string();
    my $s2 = Net::CIDR::Set->new($new_string);
    ok $set->equals( $s2 ) or
      diag("$orig_string vs $new_string",
        "\n\t(strings needn't be identical, just logically equivalent)");
  }
}

{
  # 4 tests
  my %input = (
    "60.200.0.0/24, 60.200.1.0/24, 60.200.2.0/24, 60.200.3.0/24"
      => ['60.200.0.0/22'],
    "60.200.0.0/24, 60.200.1.0/24, 60.200.2.0/24"
      => ['60.200.0.0-60.200.2.255'],
    "60.200.0.0/24, 60.200.2.0/24"
      => ['60.200.0.0/24', '60.200.2.0/24'],
    "60.200.0.0/24, 60.200.1.0/25"
      => ['60.200.0.0-60.200.1.127'],
  );
  for my $orig_string (sort keys %input) {
    my $set = Net::CIDR::Set->new($orig_string);
    my @range = $set->as_range_array();
    is_deeply(\@range, $input{$orig_string});
  }
}

# vim:ts=2:sw=2:et:ft=perl

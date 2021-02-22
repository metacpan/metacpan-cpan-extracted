#!perl -T
use 5.10.0;
use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
  use_ok('Net::IPAM::Tree')  || print "Bail out!\n";
  use_ok('Net::IPAM::Block') || print "Bail out!\n";
}

my $blocks = {
  '::/8'     => 'Reserved by IETF     [RFC3513][RFC4291]',
  '100::/8'  => 'Reserved by IETF     [RFC3513][RFC4291]',
  '200::/7'  => 'Reserved by IETF     [RFC4048]',
  '400::/6'  => 'Reserved by IETF     [RFC3513][RFC4291]',
  '800::/5'  => 'Reserved by IETF     [RFC3513][RFC4291]',
  '1000::/4' => 'Reserved by IETF     [RFC3513][RFC4291]',
  '2000::/3' => 'Global Unicast       [RFC3513][RFC4291]',
  '2000::/4' => 'Test',
  '3000::/4' => 'FREE',
  '4000::/3' => 'Reserved by IETF     [RFC3513][RFC4291]',
  '6000::/3' => 'Reserved by IETF     [RFC3513][RFC4291]',
};

my @items;
foreach my $b ( keys %$blocks ) {
  push @items, Net::IPAM::Block->new($b);
}

my $t = Net::IPAM::Tree->new;
ok( !$t->to_string, '$tree->to_string is undef if $t is empty' );

$t->insert(@items);

my $decorate_cb = sub {
  my $item       = shift;
  my $block      = $item->to_string;
  my $annotation = $blocks->{$block};

  my $ruler = '.' x ( 40 - length($block) );
  return "$block $ruler $annotation";
};

my $expect = <<EOT;
▼
├─ ::/8 .................................... Reserved by IETF     [RFC3513][RFC4291]
├─ 100::/8 ................................. Reserved by IETF     [RFC3513][RFC4291]
├─ 200::/7 ................................. Reserved by IETF     [RFC4048]
├─ 400::/6 ................................. Reserved by IETF     [RFC3513][RFC4291]
├─ 800::/5 ................................. Reserved by IETF     [RFC3513][RFC4291]
├─ 1000::/4 ................................ Reserved by IETF     [RFC3513][RFC4291]
├─ 2000::/3 ................................ Global Unicast       [RFC3513][RFC4291]
│  ├─ 2000::/4 ................................ Test
│  └─ 3000::/4 ................................ FREE
├─ 4000::/3 ................................ Reserved by IETF     [RFC3513][RFC4291]
└─ 6000::/3 ................................ Reserved by IETF     [RFC3513][RFC4291]
EOT

is( $t->to_string($decorate_cb), $expect, '$tree->to_string($decorator_cb)' );

done_testing();

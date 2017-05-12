use 5.006;
use strict;
use warnings;

use Test::More tests => 3 * 7;
use Set::Associate;
use Set::Associate::NewKey;
use Set::Associate::RefillItems;

my $et = Set::Associate->new(
  on_items_empty => Set::Associate::RefillItems->linear(
    items => [qw( hello world this is a test )],
  ),
  on_new_key => Set::Associate::NewKey->hash_md5,
);

my $got  = {};
my $xmap = {
  a => world =>,
  b => world =>,
  c => world =>,
  d => is    =>,
  e => a     =>,
  f => test  =>,
  g => test  =>,
};

for my $item (qw( a b c d e f g )) {
  $got->{$item} = $et->get_associated($item);
  ok( defined $got->{$item}, "Got something for << $item >>" );
}

for my $item (qw( a b c d e f g )) {
  is( $got->{$item}, $et->get_associated($item), "Second pass is the same ( $got->{$item} ) " );
}

for my $item (qw( a b c d e f g )) {
  is( $got->{$item}, $xmap->{$item}, "Items are expected values determined by hash ( $got->{$item} ) " );
}

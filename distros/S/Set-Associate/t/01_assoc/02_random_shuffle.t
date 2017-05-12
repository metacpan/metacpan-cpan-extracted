use 5.006;
use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal qw( exception );
use Set::Associate;
use Set::Associate::NewKey;
use Set::Associate::RefillItems;

use List::Util qw( shuffle );

ok(
  exception {
    my $et = Set::Associate->new(
      items          => [qw( hello world this is a test )],
      on_items_empty => Set::Associate::RefillItems::shuffle,
    );

    my $got = {};

    for my $item (qw( a b c d e f g )) {
      $got->{$item} = $et->get_associated($item);
      ok( defined $got->{$item}, "Got something for << $item >>" );
    }

    for my $item (qw( a b c d e f g )) {
      is( $got->{$item}, $et->get_associated($item), "Second pass is the same ( $got->{$item} ) " );
    }

  },
  'Legacy code unsupported'
);

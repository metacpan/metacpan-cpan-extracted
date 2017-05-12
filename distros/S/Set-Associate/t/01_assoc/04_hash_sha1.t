use 5.006;
use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal qw( exception );
use Set::Associate;
use Set::Associate::NewKey;
use Set::Associate::RefillItems;

ok(
  exception {
    my $et = Set::Associate->new(
      items      => [qw( hello world this is a test )],
      on_new_key => Set::Associate::NewKey::hash_sha1,
    );

    my $got  = {};
    my $xmap = {
      a => a     =>,
      b => hello =>,
      c => this  =>,
      d => this  =>,
      e => test  =>,
      f => world =>,
      g => world =>,
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

  },
  'Legacy code unsupported'
);

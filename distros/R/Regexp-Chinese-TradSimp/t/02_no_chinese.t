use strict;
use warnings;
use utf8;

use Regexp::Chinese::TradSimp;
use Test::More tests => 2;

my $english = "I like to eat rice.";

like( $english, Regexp::Chinese::TradSimp->make_regexp( $english ),
      "Text with no Chinese in matches itself." );

my $st = Regexp::Chinese::TradSimp->new;
like( $english, $st->make_regexp( $english ),
      "...even if we use an explicit object." );

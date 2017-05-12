use strict;
use warnings;
use utf8;

use Regexp::Chinese::TradSimp;
use Test::More tests => 2;

my $same = "茄子";

like( $same, Regexp::Chinese::TradSimp->make_regexp( $same ),
      "Chinese text with no trad-simp differences matches itself." );

my $st = Regexp::Chinese::TradSimp->new;
like( $same, $st->make_regexp( $same ),
      "...even if we use an explicit object." );

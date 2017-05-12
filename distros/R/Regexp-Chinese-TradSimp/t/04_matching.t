use strict;
use warnings;
use utf8;

use Regexp::Chinese::TradSimp;
use Test::More tests => 8;

my $onetrad = "雞肉";
my $onesimp = "鸡肉";
my $alltrad = "蝦餃";
my $allsimp = "虾饺";

my $st = Regexp::Chinese::TradSimp->new;

like( $onetrad, $st->make_regexp( $onetrad ),
      "Chinese text with one traditional-only character matches itself." );
like( $onesimp, $st->make_regexp( $onetrad ),
      "...also matches the simplified version." );

like( $onesimp, $st->make_regexp( $onesimp ),
      "Chinese text with one simplified-only character matches itself." );
like( $onetrad, $st->make_regexp( $onesimp ),
      "...also matches the traditional version." );

like( $alltrad, $st->make_regexp( $alltrad ),
      "Chinese text with all traditional-only characters matches itself." );
like( $allsimp, $st->make_regexp( $alltrad ),
      "...also matches the simplified version." );

like( $allsimp, $st->make_regexp( $allsimp ),
      "Chinese text with all simplified-only characters matches itself." );
like( $alltrad, $st->make_regexp( $allsimp ),
      "...also matches the traditional version." );

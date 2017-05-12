use strict;
use warnings;
use utf8;

use Regexp::Chinese::TradSimp;
use Test::More tests => 1;

my $english = "I like to eat rice.";

is( $english, Regexp::Chinese::TradSimp->desensitize( $english ),
    "We can desensitize as well as desensitise." );

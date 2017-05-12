use strict;
use warnings;
use utf8;

use Test::More tests => 2;

use_ok( "Regexp::Chinese::TradSimp" );

my $ts = Regexp::Chinese::TradSimp->new;
isa_ok( $ts, "Regexp::Chinese::TradSimp" );

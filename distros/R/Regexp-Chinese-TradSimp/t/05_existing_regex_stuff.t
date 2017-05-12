use strict;
use warnings;
use utf8;

use Regexp::Chinese::TradSimp;
use Test::More tests => 8;

my $charclass = "[水蝦]餃";
my $grouped = "(虾|带子)饺";
my $st = Regexp::Chinese::TradSimp->new;
my $regexp;

$regexp = $st->make_regexp( $charclass );
like( "水餃", $regexp, "Character classes match OK when matching exactly." );
like( "水饺", $regexp, "...also when matching some simplified." );
like( "虾饺", $regexp, "...also when matching all simplified." );
unlike( "叉燒包", $regexp, "...and don't match things that don't match!" );

$regexp = $st->make_regexp( $grouped );
like( "虾饺",   $regexp, "Bracketed groups match OK when matching exactly." );
like( "帶子餃", $regexp, "...also when matching some tradified." );
like( "蝦餃",   $regexp, "...also when matching all tradified." );
unlike( "叉燒包", $regexp, "...and don't match things that don't match!" );

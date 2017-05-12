#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use DDP;
use Data::Dumper;

use lib 't/lib';
use lib 'lib';

use_ok('PDF::Boxer::Test::SizePosition');

my $sp = PDF::Boxer::Test::SizePosition->new({
  max_width => 480,
  max_height => 800,
  width => 480,
  height => 800,
  margin_left => 20,
  margin_top => 750,

  grow => 1,
});
ok( $sp, 'new sp');
is( $sp->width, 480, 'width' );
is( $sp->height, 800, 'height' );
is( $sp->margin_right, 500, 'margin_right' );
is( $sp->margin_bottom, -50, 'margin_bottom' );
is( $sp->margin_left, 20, 'margin_left' );
is( $sp->margin_top, 750, 'margin_top' );



$sp->adjust({ width => 300 });
is( $sp->width, 300, 'width after max_width change' );
is( $sp->height, 800, 'height' );
is( $sp->margin_right, 320, 'margin_right' );
is( $sp->margin_bottom, -50, 'margin_bottom' );
is( $sp->margin_left, 20, 'margin_left' );
is( $sp->margin_top, 750, 'margin_top' );

$sp->adjust({ height => 300 });
is( $sp->height, 300, 'height after max_height change' );
is( $sp->width, 300, 'width after max_height change' );
is( $sp->margin_right, 320, 'margin_right' );
is( $sp->margin_bottom, 450, 'margin_bottom' );
is( $sp->margin_left, 20, 'margin_left' );
is( $sp->margin_top, 750, 'margin_top' );

$sp->adjust({ margin_left => 50 });
is( $sp->width, 300, 'width after margin_left change' );
is( $sp->margin_right, 350, 'margin_right after margin_left change' );
is( $sp->height, 300, 'height after max_height change' );
is( $sp->margin_bottom, 450, 'margin_bottom' );
is( $sp->margin_left, 50, 'margin_left' );
is( $sp->margin_top, 750, 'margin_top' );

$sp->adjust({ margin_top => 780 });
is( $sp->height, 300, 'height' );
is( $sp->margin_bottom, 480, 'margin_bottom after margin_top change' );
is( $sp->width, 300, 'width after margin_left change' );
is( $sp->margin_right, 350, 'margin_right after margin_left change' );
is( $sp->margin_left, 50, 'margin_left' );
is( $sp->margin_top, 780, 'margin_top' );

$sp->adjust({ width => 400 });
is( $sp->width, 400, 'width after width change' );
is( $sp->margin_right, 450, 'margin_right' );
is( $sp->height, 300, 'height' );
is( $sp->margin_bottom, 480, 'margin_bottom after margin_top change' );
is( $sp->margin_left, 50, 'margin_left' );
is( $sp->margin_top, 780, 'margin_top' );

$sp->adjust({ height => 400 });
is( $sp->height, 400, 'height' );
is( $sp->margin_bottom, 380, 'margin_bottom' );
is( $sp->width, 400, 'width after width change' );
is( $sp->margin_right, 450, 'margin_right' );
is( $sp->margin_left, 50, 'margin_left' );
is( $sp->margin_top, 780, 'margin_top' );

$sp->adjust({ margin_right => 350 });
is( $sp->width, 400, 'width after margin_right change' );
is( $sp->margin_left, -50, 'margin_left after margin_right change' );
is( $sp->height, 400, 'height' );
is( $sp->margin_bottom, 380, 'margin_bottom' );
is( $sp->margin_right, 350, 'margin_right' );
is( $sp->margin_top, 780, 'margin_top' );








done_testing();

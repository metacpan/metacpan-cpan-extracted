use strict;
use warnings;

use Test::More;
use PDL;
use PDL::IO::Image;
use Test::Number::Delta within => 0.0000001;

my $expected = [
  [0, 1, 2, 2, 2, 2, 2, 1, 1, 2, 3, 3, 2],
  [1, 1, 2, 1, 4, 2, 1, 0, 1, 2, 3, 1, 2],
  [1, 1, 2, 1, 1, 2, 1, 1, 1, 2, 1, 1, 2],
  [2, 0, 2, 2, 5, 2, 2, 6, 2, 2, 6, 2, 2],
  [1, 1, 2, 1, 1, 2, 1, 1, 1, 2, 1, 7, 2],
  [1, 1, 4, 1, 4, 2, 6, 1, 6, 2, 1, 2, 7],
  [2, 5, 2, 1, 2, 2, 2, 6, 1, 2, 1, 7, 2],
];

my $expected_region = [
  [1, 2, 1, 1, 2, 1, 1, 1],
  [0, 2, 2, 5, 2, 2, 6, 2],
];

for my $file (<t/bpp-4/*.*>) {
  my $pimage = PDL::IO::Image->new_from_file($file);
  is($pimage->get_image_type , "BITMAP", "get_image_type: $file");
  is($pimage->get_color_type , "PALETTE", "get_color_type: $file");
  is($pimage->get_colors_used, 16, "get_colors_used: $file");
  is($pimage->get_width      , 13, "get_width: $file");
  is($pimage->get_height     ,  7, "get_height: $file");
  is($pimage->get_bpp        ,  4, "get_bpp: $file");
  my $pix = $pimage->pixels_to_pdl;
  is($pix->info, 'PDL: Byte D [13,7]', "info: $file");
  is($pix->sum, 192, "sum: $file");
  delta_ok($pix->unpdl, $expected, "pixels: $file");
  #region
  $pix = $pimage->pixels_to_pdl(1,8,2,3);
  is($pix->info, 'PDL: Byte D [8,2]',     "reg.info: $file");
  is($pix->sum, 31,                       "reg.sum: $file");
  delta_ok($pix->unpdl, $expected_region, "reg.pixels: $file");
  $pix = $pimage->pixels_to_pdl(1,-4,2,-3);
  is($pix->info, 'PDL: Byte D [8,2]',     "regneg.info: $file");
  is($pix->sum, 31,                       "regneg.sum: $file");
  delta_ok($pix->unpdl, $expected_region, "regneg.pixels: $file");
}

done_testing();
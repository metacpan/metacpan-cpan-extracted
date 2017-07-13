use strict;
use warnings;

use Test::More;
use PDL;
use PDL::IO::Image;
use Test::Number::Delta relative=>0.0000001;

for my $file (<t/img-double/*.*>) {
  my $pimage = PDL::IO::Image->new_from_file($file);
  is($pimage->get_image_type , "DOUBLE", "get_image_type: $file");
  is($pimage->get_color_type , "MINISBLACK", "get_color_type: $file");
  is($pimage->get_colors_used,  0, "get_colors_used: $file");
  is($pimage->get_width      , 71, "get_width: $file");
  is($pimage->get_height     , 71, "get_height: $file");
  is($pimage->get_bpp        , 64, "get_bpp: $file");
  my $pix = $pimage->pixels_to_pdl;
  is($pix->info, 'PDL: Double D [71,71]', "info: $file");
  delta_ok($pix->sum, -23142.2, "sum: $file");
}

done_testing();
use strict;
use warnings;

use Test::More;
use PDL;
use PDL::IO::Image;
use Test::Number::Delta relative=>0.001;

for my $file (<t/img-rgbaf/*.*>) {
  my $pimage = PDL::IO::Image->new_from_file($file);
  is($pimage->get_image_type , "RGBAF", "get_image_type: $file");
  is($pimage->get_color_type , "RGBALPHA", "get_color_type: $file");
  is($pimage->get_colors_used,  0, "get_colors_used: $file");
  is($pimage->get_width      , 71, "get_width: $file");
  is($pimage->get_height     , 71, "get_height: $file");
  is($pimage->get_bpp        , 128, "get_bpp: $file");
  my $pix = $pimage->pixels_to_pdl;
  is($pix->info, 'PDL: Float D [71,71,4]', "info: $file");
  unless ($file =~ /\.(jxr)$/i) {
    delta_ok($pix->double->sum, -569749.0, "sum: $file");
  }
}

done_testing();
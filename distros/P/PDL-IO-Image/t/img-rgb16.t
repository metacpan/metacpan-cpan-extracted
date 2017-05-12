use strict;
use warnings;

use Test::More;
use PDL;
use PDL::IO::Image;
use Test::Number::Delta within => 0.0000001;

for my $file (<t/img-rgb16/*.*>) {
  my $pimage = PDL::IO::Image->new_from_file($file);
  is($pimage->get_image_type , "RGB16", "get_image_type: $file");
  is($pimage->get_color_type , "RGB", "get_color_type: $file");
  is($pimage->get_colors_used,  0, "get_colors_used: $file");
  is($pimage->get_width      , 71, "get_width: $file");
  is($pimage->get_height     , 71, "get_height: $file");
  is($pimage->get_bpp        , 48, "get_bpp: $file");
  my $pix = $pimage->pixels_to_pdl;
  is($pix->info, 'PDL: Ushort D [71,71,3]', "info: $file");
  unless ($file =~ /\.(j2k|jp2|jxr)$/i) {
    delta_ok($pix->double->sum, 497094730, "sum: $file");
  }
}

done_testing();
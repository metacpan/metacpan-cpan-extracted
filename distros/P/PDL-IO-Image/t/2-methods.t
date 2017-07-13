use strict;
use warnings;

use Test::More;
use PDL::IO::Image;

{
  my $pimage = PDL::IO::Image->new_from_file('t/bpp-32/special/png_with_extension.png');
  is($pimage->get_image_type, 'BITMAP', "get_image_type");
  is($pimage->get_colors_used, 0, "get_colors_used");
  is($pimage->get_bpp, 32, "get_bpp");
  is($pimage->get_width,  17, "get_width");
  is($pimage->get_height, 23, "get_height");
  is($pimage->get_color_type, 'RGBALPHA', "get_color_type");
  is($pimage->get_dots_per_meter_x, 2835, "get_dots_per_meter_x");
  is($pimage->get_dots_per_meter_y, 2835, "get_dots_per_meter_y");
  is($pimage->is_transparent, 1, "is_transparent");

  $pimage->set_dots_per_meter_x(1400);
  $pimage->set_dots_per_meter_y(1400);
  is($pimage->get_dots_per_meter_x, 1400, "get_dots_per_meter_x/2");
  is($pimage->get_dots_per_meter_y, 1400, "get_dots_per_meter_y/2");

  $pimage->rescale(170, 230);
  is($pimage->get_width,  170, "get_width/2");
  is($pimage->get_height, 230, "get_height/2");

  $pimage->rescale(0, 23);
  is($pimage->get_width,  17, "get_width/3");
  is($pimage->get_height, 23, "get_height/3");

  $pimage->rescale(170, 0);
  is($pimage->get_width,  170, "get_width/4");
  is($pimage->get_height, 230, "get_height/4");

  $pimage->rescale_pct(10, 0);
  is($pimage->get_width,  17, "get_width/5");
  is($pimage->get_height, 23, "get_height/5");

  $pimage->rescale_pct(0, 1000);
  is($pimage->get_width,  170, "get_width/6");
  is($pimage->get_height, 230, "get_height/6");

  $pimage->rotate(90.0);
  is($pimage->get_width,  230, "get_width/7");
  is($pimage->get_height, 170, "get_height/7");

  $pimage->flip_horizontal->flip_vertical;
  is($pimage->get_width,  230, "get_width/8");
  is($pimage->get_height, 170, "get_height/8");

  $pimage->clone->tone_mapping(1, 2.2, 0.7)->adjust_colors(0.5, 1.5, 2.5, 1)->color_quantize->color_dither->color_threshhold;
  
  $pimage->clone->color_to_32bpp->color_to_24bpp->color_to_16bpp_555->color_to_16bpp_565->color_to_8bpp->color_to_8bpp_grey->color_to_4bpp;
  my ($width, $height, $bpp, $pixels, $palette) = $pimage->clone->color_to_8bpp->dump_bitmap;
  ok($width && $height && $bpp && $pixels && $palette, "dump_bitmap");

  my $out;
  $pimage->save(\$out, "PNG");
  ok(length $out > 0, "save to scalar");
  ok(PDL::IO::Image->new_from_file(\$out), "new from scalar");
  
  $pimage->convert_image_type("FLOAT");
  is($pimage->get_image_type, 'FLOAT', "get_image_type/2");
}

{
  my $pimage = PDL::IO::Image->new_from_file('t/bpp-8/special/8x11_8tr.gif');
  is($pimage->get_transparent_index, 255, "get_transparent_index/1");
  $pimage->set_transparent_index(15);
  is($pimage->get_transparent_index, 15, "get_transparent_index/2");
}

done_testing();
use strict;
use warnings;

use PDL;
use PDL::IO::Image;

use Test::More;
use Test::Number::Delta relative=>0.0001;

use File::Temp 'tempdir';
my $tmpdir = tempdir("test-XXXXX", CLEANUP => 1);

my $pal256 = (random(3, 256) * 256)->byte;      # BITMAP bpp=8
my $pix256 = (random(17, 23) * 256)->byte;

my $pal16  = (random(3, 16) * 16)->byte;        # BITMAP bpp=4
my $pix16  = (random(17, 23) * 16)->byte;

my @pdls = (
     (random(17, 23, 4) * 10000 - 5000)->float, # RGBAF
     (random(17, 23, 3) * 10000 - 5000)->float, # RGBF
     (random(17, 23, 4) * 65536)->ushort,       # RGBA16
     (random(17, 23, 3) * 65536)->ushort,       # RGB16
     (random(17, 23, 4) * 256)->byte,           # BITMAP bpp=32
     (random(17, 23, 3) * 256)->byte,           # BITMAP bpp=24
     (random(17, 23) * 2)->byte,                # BITMAP bpp=1
     (sin((rvals(71, 71)+1)/3) * 100)->double,              # DOUBLE
     (sin((rvals(71, 71)+1)/3) * 100)->float,               # FLOAT
     (sin((rvals(71, 71)+1)/3) * 2**31 + 2**31)->longlong,  # INT32
     (sin((rvals(71, 71)+1)/3) * 2**31)->long,              # UINT32
     (sin((rvals(71, 71)+1)/3) * 2**15)->short,             # INT16
     (sin((rvals(71, 71)+1)/3) * 2**15 + 2**15)->ushort,    # UINT16
);

for my $p1 (@pdls) {
  my $im1 = PDL::IO::Image->new_from_pdl($p1);
  my $fname = "$tmpdir/test-" . $im1->get_image_type . "_" . $im1->get_bpp . ".tiff";
  $im1->save($fname);
  my $im2 = PDL::IO::Image->new_from_file($fname);

  my $p2 = $im2->pixels_to_pdl;
  is($p2->info, $p1->info);
  delta_ok($p2->sum, $p1->sum);
  delta_ok($p2->unpdl, $p1->unpdl);

  is($im2->get_image_type,  $im1->get_image_type);
  is($im2->get_color_type,  $im1->get_color_type);
  is($im2->get_colors_used, $im1->get_colors_used);
  is($im2->get_bpp,         $im1->get_bpp);
  is($im2->get_width,       $im1->get_width);
  is($im2->get_height,      $im1->get_height);
  unlink $fname;
}

for ([$pix256, $pal256], [$pix16, $pal16]) {
  my ($p1, $c1) = @$_;
  my $im1 = PDL::IO::Image->new_from_pdl($p1, $c1);
  my $fname = "$tmpdir/test-" . $im1->get_image_type . "_" . $im1->get_bpp . "_pal.tiff";
  $im1->save($fname);
  my $im2 = PDL::IO::Image->new_from_file($fname);

  my $c2 = $im2->palette_to_pdl;
  is($c2->info, $c1->info);
  delta_ok($c2->sum, $c1->sum);
  delta_ok($c2->unpdl, $c1->unpdl);

  my $p2 = $im2->pixels_to_pdl;
  is($p2->info, $p1->info);
  delta_ok($p2->sum, $p1->sum);
  delta_ok($p2->unpdl, $p1->unpdl);

  is($im2->get_image_type,  $im1->get_image_type);
  is($im2->get_color_type,  $im1->get_color_type);
  is($im2->get_colors_used, $im1->get_colors_used);
  is($im2->get_bpp,         $im1->get_bpp);
  is($im2->get_width,       $im1->get_width);
  is($im2->get_height,      $im1->get_height);
}

for my $p1 (@pdls) {
  my $fname = "$tmpdir/test.tiff";
  wimage($p1, $fname);
  #$p1->wimage($fname);
  my $p2 = rimage($fname);
  is($p2->info, $p1->info);
  delta_ok($p2->unpdl, $p1->unpdl);
}

for ([$pix256, $pal256], [$pix16, $pal16]) {
  my ($p1, $c1) = @$_;
  my $fname = "$tmpdir/test.tiff";
  #wimage($p1, $fname, {palette=>$c1});
  $p1->wimage($fname, {palette=>$c1});
  my ($p2, $c2) = rimage($fname, {palette=>1});
  is($p2->info, $p1->info);
  delta_ok($p2->unpdl, $p1->unpdl);
  is($c2->info, $c1->info);
  delta_ok($c2->unpdl, $c1->unpdl);
}

done_testing();
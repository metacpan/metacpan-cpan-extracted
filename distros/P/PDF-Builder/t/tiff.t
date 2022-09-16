#!/usr/bin/perl
use warnings;
use strict;
use English qw( -no_match_vars );
use IPC::Cmd qw(can_run run);
use File::Spec;
use File::Temp;
use version;
use Test::More tests => 19;
#use Test::More tests => 25;   when TIFF changes in

use PDF::Builder;
# 0: allow use of Graphics::TIFF, 1: force non-GT usage
my $noGT = 0;
my $diag = '';
my $failed;

# Filename 3 tests ------------------
# tests 1 and 3 will mention TIFF_GT if Graphics::TIFF is installed and
# usable, otherwise they will display just TIFF. you can use this information
# if you are not sure about the status of Graphics::TIFF.

my $pdf = PDF::Builder->new('-compress' => 'none'); # common $pdf all tests
my $has_GT = 0; # global flag for all tests that need to know if Graphics::TIFF
my ($page, $img, $example, $expected);

# -silent shuts off one-time warning for rest of run
my $tiff = $pdf->image_tiff('t/resources/1x1.tif', -silent => 1, -nouseGT => $noGT);
# 1
if ($tiff->usesLib() == 1) {
    $has_GT = 1;
    isa_ok($tiff, 'PDF::Builder::Resource::XObject::Image::TIFF_GT',
        q{$pdf->image_tiff(filename)});
} else {
    isa_ok($tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
        q{$pdf->image_tiff(filename)});
}

# 2
is($tiff->width(), 1,
   q{Image from filename has a width});

# 3
my $gfx = $pdf->page()->gfx();
$gfx->image($tiff, 72, 144, 216, 288);
like($pdf->to_string(), qr/q 216 0 0 288 72 144 cm \S+ Do Q/,
     q{Add TIFF to PDF});

# Filehandle (old library only)  2 tests ------------------

# 4
$pdf = PDF::Builder->new();
open my $fh, '<', 't/resources/1x1.tif' or
   die "Couldn't open file t/resources/1x1.tif";
$tiff = $pdf->image_tiff($fh, -nouseGT => 1);
isa_ok($tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
    q{$pdf->image_tiff(filehandle)});

# 5
is($tiff->width(), 1,
   q{Image from filehandle has a width});

close $fh;

# LZW Compression  2 tests ------------------

$pdf = PDF::Builder->new('-compress' => 'none');

# 6
my $lzw_tiff = $pdf->image_tiff('t/resources/1x1-lzw.tif', -nouseGT => $noGT);
if ($lzw_tiff->usesLib() == 1) {
    isa_ok($lzw_tiff, 'PDF::Builder::Resource::XObject::Image::TIFF_GT',
        q{$pdf->image_tiff(), LZW compression});
} else {
    isa_ok($lzw_tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
        q{$pdf->image_tiff(), LZW compression});
}

$gfx = $pdf->page()->gfx();
$gfx->image($lzw_tiff, 72, 360, 216, 432);

# 7
like($pdf->to_string(), qr/q 216 0 0 432 72 360 cm \S+ Do Q/,
     q{Add TIFF to PDF});

# Missing file  1 test ------------------

# 8
$pdf = PDF::Builder->new();
eval { $pdf->image_tiff('t/resources/this.file.does.not.exist', -nouseGT => $noGT) };
ok($@, q{Fail fast if the requested file doesn't exist});

##############################################################
# common data for remaining tests
my $width = 1000;
my $height = 100;
my $directory = File::Temp->newdir();
my $tiff_f = File::Spec->catfile($directory, 'test.tif');
my $pdfout = File::Spec->catfile($directory, 'test.pdf');
my $pngout = File::Spec->catfile($directory, 'out.png');

# NOTE: following 4 tests use 'convert' tool from ImageMagick.
# They may require software installation on your system, and
# will be skipped if the necessary software is not found.
#
# Some of the following tests will need ghostScript on Windows platforms.
# Note that GS installation MAY not permanently add GS to %Path% -- you
#   may have to do this manually

my ($convert, $gs, $convertX, $gsX);
# ImageMagick pre-v7 has a "convert" utility.
# On v7, this is called via "magick convert"
# On Windows, be careful NOT to run "convert", as this is a HDD reformatter!
if      (can_run("magick")) {
    $convert = "magick convert";
} elsif ($OSNAME ne 'MSWin32' and can_run("convert")) {
    $convert = "convert";
}
# check if reasonably recent version
$convert = check_version($convert, '-version', 'ImageMagick ([0-9.]+)', '6.9.7');
# use $convertX instead of $convert in selected tests if IM excluded version 
# (error) found
#$convertX = exclude_version($convert, '-v', 'ImageMagick ([0-9.]+)', 
#         ['8.0.4','100.0', ]);
#$convertX = $convert;  # if want to keep tests changed, but not exclude

# $convert undef if not installed, can't parse format, version too low
# will skip "No ImageMagick"

# on Windows, ImageMagick can be 64-bit or 32-bit version, so try both. it's
#   needed for some magick convert operations, and also standalone, and
#   usually must be installed.
# on Linux-like systems, it's usually just 'gs' and comes with the platform.
if      (can_run("gswin64c")) {
    $gs = "gswin64c";
} elsif (can_run("gswin32c")) {
    $gs = "gswin32c";
} elsif (can_run("gs")) {
    $gs = "gs";
}
# check if reasonably recent version
$gs = check_version($gs, '-v', 'Ghostscript ([0-9.]+)', '9.25.0');
# use $gsX instead of $gs in selected tests if GS excluded version (error) found
$gsX = exclude_version($gs, '-v', 'Ghostscript ([0-9.]+)', 
         ['9.56.0','9.56.1', ]);
#$gsX = $gs;  # if want to keep tests changed, but not exclude

# $convert undef if not installed, can't parse format, version too low
# will skip "No Ghostscript"

# alpha layer handling ------------------
# convert and Graphics::TIFF needed

# 9
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gs and $has_GT;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox($width, $height);
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => $noGT);
$gfx->image($img, 0, 0, $width, $height);
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pngalpha -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
my $example = `$convert $pngout -colorspace gray -depth 1 txt:-`;
my $expected = `$convert $tiff_f -depth 1 txt:-`;
# ----------

is($example, $expected, 'alpha + flate') or show_diag();
}

# G4 (NOT converted to Flate) ------------------
# convert and Graphics::TIFF are needed

# 10
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gs and $has_GT;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -background white -alpha off -compress Group4 $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox($width, $height);
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => $noGT);
$gfx->image($img, 0, 0, $width, $height);
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 txt:-`;
$expected = `$convert $tiff_f -depth 1 txt:-`;
# ----------

is($example, $expected, 'G4 (not converted to flate)') or show_diag();
}

# LZW (NOT converted to Flate) ------------------
# convert and Graphics::TIFF needed for these two tests

# 11
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gs and $has_GT;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -background white -alpha off -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'single-strip lzw (not converted to flate) with GT') or show_diag();
}

# 12
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gs and $has_GT;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -background white -alpha off -define tiff:rows-per-strip=50 -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'multi-strip lzw (not converted to flate) with GT') or show_diag();
}

# 13
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gsX and $has_GT;

$width = 20;
$height = 20;
system("$convert -depth 8 -size 2x2 pattern:gray50 -scale 1000% -alpha off -define tiff:predictor=2 -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 8 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 8 -alpha off txt:-`;
# ----------

is($example, $expected, 'lzw+horizontal predictor (not converted to flate) with GT') or show_diag();
}

# 14
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gs and $has_GT;

$width = 1000;
$height = 100;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => $noGT);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pngalpha -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -colorspace gray -depth 1 txt:-`;
$expected = `$convert $tiff_f -depth 1 txt:-`;
# ----------

is($example, $expected, 'alpha + lzw') or show_diag();
}

# 15
SKIP: {
    skip "Either ImageMagick or Ghostscript not available.", 1 unless
        defined $convert and defined $gs;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -background white -alpha off -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 1);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'single-strip lzw (not converted to flate) without GT') or show_diag();
}

SKIP: {
    skip "Either ImageMagick or Ghostscript not available.", 1 unless
        defined $convert and defined $gsX;

# 16
$width = 20;
$height = 20;
system("$convert -depth 8 -size 2x2 pattern:gray50 -scale 1000% -alpha off -define tiff:predictor=2 -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 1);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'lzw+horizontal predictor (not converted to flate) without GT') or show_diag();
$width = 1000;
$height = 100;
}

# 17    TODO
SKIP: {
    skip "multi-strip lzw without GT is not currently supported", 1;
system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -background white -alpha off -define tiff:rows-per-strip=50 -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 1);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'multi-strip lzw (not converted to flate) without GT') or show_diag();
}

# read TIFF with colormap ------------------
# convert and Graphics::TIFF needed for this test

# 18
SKIP: {
    skip "Either ImageMagick or Graphics::TIFF not available.", 1 unless
        defined $convert and $has_GT;

# .png file is temporary file (output, input, erased)
my $colormap = File::Spec->catfile($directory, 'colormap.png');
system("$convert rose: -type palette -depth 2 $colormap");
system("$convert $colormap $tiff_f");
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page;
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => $noGT);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();
pass 'successfully read TIFF with colormap';
}

# 19
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gs and $has_GT;

$width = 6;
$height = 1;
system("$convert -depth 1 -size ${width}x${height} pattern:gray50 -alpha on $tiff_f");
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# "For reasons I don't understand, gs swaps the last two pixels here, so let's
# ignore them." This glitch is reported by @carygravel ("gs consistently 
# swapped two pixels in the last byte of the first row" over multiple test 
# images), but the PDF produced appears to be OK -- it's just something odd 
# happening in producing the PNG for comparison. We'll keep an eye on it, as I 
# don't particularly like magic solutions. See PR #165.
$example =~ s/(.*\n).*\n.*\n$/$1/;
$expected =~ s/(.*\n).*\n.*\n$/$1/;
# ----------

is($example, $expected, "bilevel and alpha when width not a whole number of bytes with GT") or show_diag();
}

if (0) {           ####################################### when TIFF changes in
# 20    TODO
SKIP: {
     skip "alpha layer without GT is not currently supported", 1;
#SKIP: {
#    skip "Either ImageMagick or Ghostscript not available.", 1 unless
#        defined $convert and defined $gs;
$width = 6;
$height = 1;
system("$convert -depth 1 -size ${width}x${height} pattern:gray50 -alpha on $tiff_f");
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 1);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# for reasons I don't understand, gs swaps the last two pixels here, so let's
# ignore them
$example =~ s/(.*\n).*\n.*\n$/$1/;
$expected =~ s/(.*\n).*\n.*\n$/$1/;
# ----------

is($example, $expected, "bilevel and alpha when width not a whole number of bytes without GT");
}

# 21
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gs and $has_GT;

$width = 6;
$height = 2;
system("$convert -depth 1 -size ${width}x${height} pattern:gray50 -alpha off -define tiff:rows-per-strip=1 -compress fax $tiff_f");
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'multi-strip group 3 (not converted to flate) with GT');
}

# 22
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gs and $has_GT;

$width = 6;
$height = 2;
system("$convert -depth 1 -size ${width}x${height} pattern:gray50 -alpha off -define tiff:rows-per-strip=1 -compress group4 $tiff_f");
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'multi-strip g4 (not converted to flate) with GT');
}

# 23
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gs and $has_GT;

$width = 6;
$height = 2;
system("$convert -depth 1 -size ${width}x${height} pattern:gray50 -alpha off -define tiff:rows-per-strip=1 -define quantum:polarity=min-is-black -compress fax $tiff_f");
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'multi-strip g3 min-is-black (not converted to flate) with GT');
}

# 24
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gs and $has_GT;

$width = 6;
$height = 2;
system("$convert -depth 1 -size ${width}x${height} pattern:gray50 -alpha off -define tiff:rows-per-strip=1 -define quantum:polarity=min-is-black -compress group4 $tiff_f");
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'multi-strip g4 min-is-black (not converted to flate) with GT');
}

# 25
SKIP: {
    skip "Either ImageMagick, Ghostscript or Graphics::TIFF not available.", 1 unless
        defined $convert and defined $gs and $has_GT;

$width = 6;
$height = 2;
system("$convert -depth 1 -size ${width}x${height} pattern:gray50 -alpha off -define tiff:fill-order=lsb -compress group4 $tiff_f");
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'LSB fillorder with GT');
}
}                  ####################################### when TIFF changes in

##############################################################
# cleanup. all tests involving these files skipped?

# check non-Perl utility versions
sub check_version {
    my ($cmd, $arg, $regex, $min_ver) = @_;

    # was the check routine already defined (installed)?
    if (defined $cmd) {
	# should match dotted version number
        my $output = `$cmd $arg`;
        $diag .= $output;
	if ($output =~ m/$regex/) {
	    if (version->parse($1) >= version->parse($min_ver)) {
		return $cmd;
	    }
	}
    }
    return; # cmd not defined (not installed) so return undef
}

# exclude specified non-Perl utility versions
# do not call if don't have one or more exclusion ranges
sub exclude_version {
    my ($cmd, $arg, $regex, $ex_ver_r) = @_;

    my (@ex_ver, $my_ver);
    if (defined $ex_ver_r) {
	@ex_ver = @$ex_ver_r;
    } else {
	return; # called w/o exclusion list: fail
    }
    # need 2, 4, 6,... dotted versions
    if (!scalar(@ex_ver) || scalar(@ex_ver)%2) {
	return; # called with zero or odd number of elements: fail
    }

    if (defined $cmd) {
	# dotted version number should not fall into an excluded range
        my $output = `$cmd $arg`;
        $diag .= $output;
	if ($output =~ m/$regex/) {
	    $my_ver = version->parse($1);
	    for (my $i=0; $i<scalar(@ex_ver); $i+=2) {
	        if ($my_ver >= version->parse($ex_ver[$i  ]) &&
		    $my_ver <= version->parse($ex_ver[$i+1])) {
		    return; # fell into one of the exclusion ranges
	        }
	    }
	    return $cmd; # didn't hit any exclusions, so OK
	}
    }
    return; # cmd not defined (not installed) so return undef
}

sub show_diag { 
    $failed = 1;
    return;
}

if ($failed) { diag($diag) }

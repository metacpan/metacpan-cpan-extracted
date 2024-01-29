#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 49;

use PDF::Builder;
my ($pdf, $page, $pdf2, $pdf_string, $media, $sizes_PDF, $sizes_page, @box);

#### TBD when a deprecated interface is removed, keep the test for the new
####     replacement here, while commenting out the old interface

## new_api  -- removed from PDF::Builder, deprecated in PDF::API2
#use PDF::Builder::Resource::XObject::Image::JPEG;
#$pdf = PDF::Builder->new();
#my $image = PDF::Builder::Resource::XObject::Image::JPEG->new_api($pdf, 't/resources/1x1.jpg');
#ok($image, q{new_api still works});
# TBD need test for replacement call

# create a dummy PDF (as string) for further tests
$pdf = PDF::Builder->new();
$pdf->page()->gfx()->fillcolor('blue');
$pdf_string = $pdf->to_string();

## openScalar() -> open_scalar() -> from_string()
$pdf = PDF::Builder->openScalar($pdf_string);
is(ref($pdf), 'PDF::Builder',
   q{openScalar still works});
$pdf = PDF::Builder->open_scalar($pdf_string);
is(ref($pdf), 'PDF::Builder',
   q{open_scalar replacement for openScalar IS available});
$pdf = PDF::Builder->from_string($pdf_string);
is(ref($pdf), 'PDF::Builder',
   q{from_string replacement for openScalar and open_scalar IS available});

## importpage() -> import_page()
#  removed from PDF::Builder, deprecated in PDF::API2
$pdf2 = PDF::Builder->new();
#$page = $pdf2->importpage($pdf, 1);
#is(ref($page), 'PDF::Builder::Page',
#   q{importpage still works});
$page = $pdf2->import_page($pdf, 1);
is(ref($page), 'PDF::Builder::Page',
   q{import_page replacement for importpage IS available});

## openpage() -> open_page()
#  replaced by open_page in API2
$pdf2 = PDF::Builder->from_string($pdf_string);
$page = $pdf2->openpage(1);
is(ref($page), 'PDF::Builder::Page',
   q{openpage still works});
$page = $pdf2->open_page(1);
is(ref($page), 'PDF::Builder::Page',
   q{open_page replacement for openpage IS available});

# PDF::Builder-specific cases to ADD tests for (deprecated but NOT yet removed):
#
##  elementsof() -> elements()
$pdf2 = PDF::Builder->new();
$page = $pdf2->page();
# should be US letter [ 0 0 612 792 ] for default media
#$media = $page->find_prop('MediaBox');
#$media = [ map { $_->val() } $media->elementsof() ];
#ok($media->[0]==0 && $media->[1]==0 && $media->[2]==612 && $media->[3]==792,
    #q{elementsof still works});
$media = $page->find_prop('MediaBox');
$media = [ map { $_->val() } $media->elements() ];
ok($media->[0]==0 && $media->[1]==0 && $media->[2]==612 && $media->[3]==792,
    q{elements replacement for elementsof IS available});
 
#  removeobj() -> (gone)

#  get_mediabox() -> mediabox()
#  default mediabox size, inherited by page
# should be US letter [ 0 0 612 792 ] for default media
$sizes_PDF  = [0, 0, 612, 792];
$sizes_page = [0, 0, 612, 792];
$pdf2 = PDF::Builder->new();
$page = $pdf2->page();
#@box = $page->get_mediabox();
#ok(array_comp($sizes_page, @box),
#    q{get_mediabox still works for default page media size});
@box = $pdf2->mediabox();
ok(array_comp($sizes_PDF, @box),
    q{mediabox IS available for default PDF media size});
@box = $page->mediabox();
ok(array_comp($sizes_page, @box),
    q{mediabox replacement for get_mediabox IS available for default page media size});

#  set mediabox at PDF, page should inherit
$sizes_PDF  = [ 0, 0, 100, 150 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$pdf2->mediabox(0, 0, 100, 150);
$page = $pdf2->page();
#@box = $page->get_mediabox();
#ok(array_comp($sizes_page, @box),
#    q{get_mediabox still works for PDF-set page media size});
@box = $pdf2->mediabox();
ok(array_comp($sizes_PDF, @box),
    q{mediabox IS available for PDF-set PDF media size});
@box = $page->mediabox();
ok(array_comp($sizes_page, @box),
    q{mediabox replacement for get_mediabox IS available for PDF-set page media size});

#  set mediabox at page, PDF is default
$sizes_PDF  = [ 0, 0, 612, 792 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$page = $pdf2->page();
$page->mediabox(0, 0, 100, 150);
#@box = $page->get_mediabox();
#ok(array_comp($sizes_page, @box),
#    q{get_mediabox still works for page-set page media size});
@box = $pdf2->mediabox();
ok(array_comp($sizes_PDF, @box),
    q{mediabox IS available for default PDF media size});
@box = $page->mediabox();
ok(array_comp($sizes_page, @box),
    q{mediabox replacement for get_mediabox IS available for page-set page media size});

#  set mediabox at PDF and page
$sizes_PDF  = [ 0, 0, 200, 300 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$pdf2->mediabox(0, 0, 200, 300);
$page = $pdf2->page();
$page->mediabox(0, 0, 100, 150);
#@box = $page->get_mediabox();
#ok(array_comp($sizes_page, @box),
#    q{get_mediabox still works for page-set page media size});
@box = $pdf2->mediabox();
ok(array_comp($sizes_PDF, @box),
    q{mediabox IS available for PDF-set PDF media size});
@box = $page->mediabox();
ok(array_comp($sizes_page, @box),
    q{mediabox replacement for get_mediabox IS available for page-set page media size});

#  get_cropbox() -> cropbox()
#  default cropbox size, inherited by page
#  should be US letter [ 0 0 612 792 ] for default media
$sizes_PDF  = [0, 0, 612, 792];
$sizes_page = [0, 0, 612, 792];
$pdf2 = PDF::Builder->new();
$page = $pdf2->page();
#@box = $page->get_cropbox();
#ok(array_comp($sizes_page, @box),
#    q{get_cropbox still works for default page cropbox size});
@box = $pdf2->cropbox();
ok(array_comp($sizes_PDF, @box),
    q{cropbox IS available for default PDF cropbox size});
@box = $page->cropbox();
ok(array_comp($sizes_page, @box),
    q{cropbox replacement for get_cropbox IS available for default page cropbox size});

#  set cropbox at PDF, page should inherit
$sizes_PDF  = [ 0, 0, 100, 150 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$pdf2->cropbox(0, 0, 100, 150);
$page = $pdf2->page();
#@box = $page->get_cropbox();
#ok(array_comp($sizes_page, @box),
#    q{get_cropbox still works for PDF-set page cropbox size});
@box = $pdf2->cropbox();
ok(array_comp($sizes_PDF, @box),
    q{cropbox IS available for PDF-set PDF cropbox size});
@box = $page->cropbox();
ok(array_comp($sizes_page, @box),
    q{cropbox replacement for get_cropbox IS available for PDF-set page cropbox size});

#  set cropbox at page, PDF is default
$sizes_PDF  = [ 0, 0, 612, 792 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$page = $pdf2->page();
$page->cropbox(0, 0, 100, 150);
#@box = $page->get_cropbox();
#ok(array_comp($sizes_page, @box),
#    q{get_cropbox still works for page-set page cropbox size});
@box = $pdf2->cropbox();
ok(array_comp($sizes_PDF, @box),
    q{cropbox IS available for default PDF cropbox size});
@box = $page->cropbox();
ok(array_comp($sizes_page, @box),
    q{cropbox replacement for get_cropbox IS available for page-set page cropbox size});

#  set cropbox at PDF and page
$sizes_PDF  = [ 0, 0, 200, 300 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$pdf2->cropbox(0, 0, 200, 300);
$page = $pdf2->page();
$page->cropbox(0, 0, 100, 150);
#@box = $page->get_cropbox();
#ok(array_comp($sizes_page, @box),
#    q{get_cropbox still works for page-set page cropbox size});
@box = $pdf2->cropbox();
ok(array_comp($sizes_PDF, @box),
    q{cropbox IS available for PDF-set PDF cropbox size});
@box = $page->cropbox();
ok(array_comp($sizes_page, @box),
    q{cropbox replacement for get_cropbox IS available for page-set page cropbox size});

#  get_bleedbox() -> bleedbox()
#  default bleedbox size, inherited by page
#  should be US letter [ 0 0 612 792 ] for default media
$sizes_PDF  = [0, 0, 612, 792];
$sizes_page = [0, 0, 612, 792];
$pdf2 = PDF::Builder->new();
$page = $pdf2->page();
#@box = $page->get_bleedbox();
#ok(array_comp($sizes_page, @box),
#    q{get_bleedbox still works for default page bleedbox size});
@box = $pdf2->bleedbox();
ok(array_comp($sizes_PDF, @box),
    q{bleedbox IS available for default PDF bleedbox size});
@box = $page->bleedbox();
ok(array_comp($sizes_page, @box),
    q{bleedbox replacement for get_bleedbox IS available for default page bleedbox size});

#  set bleedbox at PDF, page should inherit
$sizes_PDF  = [ 0, 0, 100, 150 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$pdf2->bleedbox(0, 0, 100, 150);
$page = $pdf2->page();
#@box = $page->get_bleedbox();
#ok(array_comp($sizes_page, @box),
#    q{get_bleedbox still works for PDF-set page bleedbox size});
@box = $pdf2->bleedbox();
ok(array_comp($sizes_PDF, @box),
    q{bleedbox IS available for PDF-set PDF bleedbox size});
@box = $page->bleedbox();
ok(array_comp($sizes_page, @box),
    q{bleedbox replacement for get_bleedbox IS available for PDF-set page bleedbox size});

#  set bleedbox at page, PDF is default
$sizes_PDF  = [ 0, 0, 612, 792 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$page = $pdf2->page();
$page->bleedbox(0, 0, 100, 150);
#@box = $page->get_bleedbox();
#ok(array_comp($sizes_page, @box),
#    q{get_bleedbox still works for page-set page bleedbox size});
@box = $pdf2->bleedbox();
ok(array_comp($sizes_PDF, @box),
    q{bleedbox IS available for default PDF bleedbox size});
@box = $page->bleedbox();
ok(array_comp($sizes_page, @box),
    q{bleedbox replacement for get_bleedbox IS available for page-set page bleedbox size});

#  set bleedbox at PDF and page
$sizes_PDF  = [ 0, 0, 200, 300 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$pdf2->bleedbox(0, 0, 200, 300);
$page = $pdf2->page();
$page->bleedbox(0, 0, 100, 150);
#@box = $page->get_bleedbox();
#ok(array_comp($sizes_page, @box),
#    q{get_bleedbox still works for page-set page bleedbox size});
@box = $pdf2->bleedbox();
ok(array_comp($sizes_PDF, @box),
    q{bleedbox IS available for PDF-set PDF bleedbox size});
@box = $page->bleedbox();
ok(array_comp($sizes_page, @box),
    q{bleedbox replacement for get_bleedbox IS available for page-set page bleedbox size});

#  get_trimbox() -> trimbox()
#  default trimbox size, inherited by page
#  should be US letter [ 0 0 612 792 ] for default media
$sizes_PDF  = [0, 0, 612, 792];
$sizes_page = [0, 0, 612, 792];
$pdf2 = PDF::Builder->new();
$page = $pdf2->page();
#@box = $page->get_trimbox();
#ok(array_comp($sizes_page, @box),
#    q{get_trimbox still works for default page trimbox size});
@box = $pdf2->trimbox();
ok(array_comp($sizes_PDF, @box),
    q{trimbox IS available for default PDF trimbox size});
@box = $page->trimbox();
ok(array_comp($sizes_page, @box),
    q{trimbox replacement for get_trimbox IS available for default page trimbox size});

#  set trimbox at PDF, page should inherit
$sizes_PDF  = [ 0, 0, 100, 150 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$pdf2->trimbox(0, 0, 100, 150);
$page = $pdf2->page();
#@box = $page->get_trimbox();
#ok(array_comp($sizes_page, @box),
#    q{get_trimbox still works for PDF-set page trimbox size});
@box = $pdf2->trimbox();
ok(array_comp($sizes_PDF, @box),
    q{trimbox IS available for PDF-set PDF trimbox size});
@box = $page->trimbox();
ok(array_comp($sizes_page, @box),
    q{trimbox replacement for get_trimbox IS available for PDF-set page trimbox size});

#  set trimbox at page, PDF is default
$sizes_PDF  = [ 0, 0, 612, 792 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$page = $pdf2->page();
$page->trimbox(0, 0, 100, 150);
#@box = $page->get_trimbox();
#ok(array_comp($sizes_page, @box),
#    q{get_trimbox still works for page-set page trimbox size});
@box = $pdf2->trimbox();
ok(array_comp($sizes_PDF, @box),
    q{trimbox IS available for default PDF trimbox size});
@box = $page->trimbox();
ok(array_comp($sizes_page, @box),
    q{trimbox replacement for get_trimbox IS available for page-set page trimbox size});

#  set trimbox at PDF and page
$sizes_PDF  = [ 0, 0, 200, 300 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$pdf2->trimbox(0, 0, 200, 300);
$page = $pdf2->page();
$page->trimbox(0, 0, 100, 150);
#@box = $page->get_trimbox();
#ok(array_comp($sizes_page, @box),
#    q{get_trimbox still works for page-set page trimbox size});
@box = $pdf2->trimbox();
ok(array_comp($sizes_PDF, @box),
    q{trimbox IS available for PDF-set PDF trimbox size});
@box = $page->trimbox();
ok(array_comp($sizes_page, @box),
    q{trimbox replacement for get_trimbox IS available for page-set page trimbox size});

#  get_artbox() -> artbox()
#  default artbox size, inherited by page
#  should be US letter [ 0 0 612 792 ] for default media
$sizes_PDF  = [0, 0, 612, 792];
$sizes_page = [0, 0, 612, 792];
$pdf2 = PDF::Builder->new();
$page = $pdf2->page();
#@box = $page->get_artbox();
#ok(array_comp($sizes_page, @box),
#    q{get_artbox still works for default page artbox size});
@box = $pdf2->artbox();
ok(array_comp($sizes_PDF, @box),
    q{artbox IS available for default PDF artbox size});
@box = $page->artbox();
ok(array_comp($sizes_page, @box),
    q{artbox replacement for get_artbox IS available for default page artbox size});

#  set artbox at PDF, page should inherit
$sizes_PDF  = [ 0, 0, 100, 150 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$pdf2->artbox(0, 0, 100, 150);
$page = $pdf2->page();
#@box = $page->get_artbox();
#ok(array_comp($sizes_page, @box),
#    q{get_artbox still works for PDF-set page artbox size});
@box = $pdf2->artbox();
ok(array_comp($sizes_PDF, @box),
    q{artbox IS available for PDF-set PDF artbox size});
@box = $page->artbox();
ok(array_comp($sizes_page, @box),
    q{artbox replacement for get_artbox IS available for PDF-set page artbox size});

#  set artbox at page, PDF is default
$sizes_PDF  = [ 0, 0, 612, 792 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$page = $pdf2->page();
$page->artbox(0, 0, 100, 150);
#@box = $page->get_artbox();
#ok(array_comp($sizes_page, @box),
#    q{get_artbox still works for page-set page artbox size});
@box = $pdf2->artbox();
ok(array_comp($sizes_PDF, @box),
    q{artbox IS available for default PDF artbox size});
@box = $page->artbox();
ok(array_comp($sizes_page, @box),
    q{artbox replacement for get_artbox IS available for page-set page artbox size});

#  set artbox at PDF and page
$sizes_PDF  = [ 0, 0, 200, 300 ];
$sizes_page = [ 0, 0, 100, 150 ];
$pdf2 = PDF::Builder->new();
$pdf2->artbox(0, 0, 200, 300);
$page = $pdf2->page();
$page->artbox(0, 0, 100, 150);
#@box = $page->get_artbox();
#ok(array_comp($sizes_page, @box),
#    q{get_artbox still works for page-set page artbox size});
@box = $pdf2->artbox();
ok(array_comp($sizes_PDF, @box),
    q{artbox IS available for PDF-set PDF artbox size});
@box = $page->artbox();
ok(array_comp($sizes_page, @box),
    q{artbox replacement for get_artbox IS available for page-set page artbox size});

# Invalid input to pageLabel
{ # for local declaration
    $pdf = PDF::Builder->new();
    local $SIG{__WARN__} = sub {};
    $pdf->pageLabel(0, { 'style' => 'arabic' });
    like($pdf->to_string(), qr{/PageLabels << /Nums \[ 0 << /S /D >> \] >>},
	 q{pageLabel defaults to decimal if given invalid input});
}

## 
## ===== scheduled to be REMOVED 3/2023
##  lead() -> leading() 
#$pdf2 = PDF::Builder->new('compress' => 'none');
#my $text = $pdf2->page()->text();
#$text->lead(15);
#like($pdf2->to_string(), qr/15 TL/, q{lead still works });
$pdf2 = PDF::Builder->new('compress' => 'none');
my $text = $pdf2->page()->text();
$text->leading(15);
like($pdf2->to_string(), qr/15 TL/, q{leading replacement for lead IS available});
##
##  textlead() -> textleading()   Lite.pm only, no t test

# if nothing left to check...
#is(ref($pdf), 'PDF::Builder',
#    q{No deprecated tests to run at this time});

sub array_comp {
   my ($expected_size_ref, @got_size) = @_;
   my $len_e = scalar(@{$expected_size_ref});
   my $len_g = scalar(@got_size);
   if ($len_e != $len_g) { return 0; }
   for (my $e = 0; $e < $len_e; $e++) {
       if ($expected_size_ref->[$e] != $got_size[$e]) { return 0; }
   }
   return 1;
}

1;

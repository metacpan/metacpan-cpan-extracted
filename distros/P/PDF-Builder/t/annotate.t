#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;

use PDF::Builder;
use PDF::Builder::Basic::PDF::Array;

my $pdf = PDF::Builder->new('compress' => 'none');
my $page = $pdf->page();

# (1) Text annotation

my $annotation = $page->annotation();
$annotation->text('This is an annotation', 'rect' => [ 72, 144, 172, 244 ]);

my $string = $pdf->to_string();
like($string,
     qr{/Annot /Subtype /Text /Border \[ 0 0 0 \] /Contents \(This is an annotation\) /Rect \[ 72 144 172 244 \]},
     q{Text Annotation in a rectangle});

# (2) Link annotation 

$pdf        = PDF::Builder->new();
$page       = $pdf->page();
$annotation = $page->annotation();

my $page2 = $pdf->page();
$annotation->goto($page2);

$string = $pdf->to_string();
like($string,
    qr{/Annot /Subtype /Link /A << /D \[ \d+ 0 R /XYZ null null null \] /S /GoTo >>},
    q{Link Annotation});

# (3) URL annotation

$pdf        = PDF::Builder->new();
$page       = $pdf->page();
$annotation = $page->annotation();

$annotation->uri('http://perl.org');

$string = $pdf->to_string();
like($string,
    qr{/Annot /Subtype /Link /A << /S /URI /URI \(http://perl.org\) >>},
    q{URL Annotation});

# (4) File annotation

$pdf        = PDF::Builder->new();
$page       = $pdf->page();
$annotation = $page->annotation();

$annotation->launch('test.pdf');

$string = $pdf->to_string();
like($string,
    qr{/Annot /Subtype /Link /A << /F \(test.pdf\) /S /Launch >>},
    q{File Annotation});

# (5) PDF File annotation

$pdf        = PDF::Builder->new();
$page       = $pdf->page();
$annotation = $page->annotation();

$annotation->pdf('test.pdf', 2);

$string = $pdf->to_string();
like($string,
    qr{/Annot /Subtype /Link /A << /D \[ 1 /XYZ null null null \] /F \(test.pdf\) /S /GoToR >>},
    q{PDF File Annotation});

# [RT #118352] Crash if $page->annotation is called on a page with an
# existing Annots array stored in an indirect object

# (6) add to existing annotation

$pdf = PDF::Builder->new();
$page = $pdf->page();

my $array = PDF::Builder::Basic::PDF::Array->new();
$pdf->{'pdf'}->new_obj($array);

$page->{'Annots'} = $array;
$page->update();
$string = $pdf->to_string();

$pdf = PDF::Builder->from_string($string);
$page = $pdf->open_page(1);
$annotation = $page->annotation();

$annotation->text('This is an annotation', 'rect' => [ 72, 144, 172, 244 ]);

$string = $pdf->to_string();
like($string,
     qr{/Annot /Subtype /Text /Border \[ 0 0 0 \] /Contents \(This is an annotation\) /Rect \[ 72 144 172 244 \]},
     q{Add an annotation to an existing annotations array stored in an indirect object});

1;

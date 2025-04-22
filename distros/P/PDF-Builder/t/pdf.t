#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 16;

use File::Temp qw(tempfile);
use PDF::Builder;

my $pdf = PDF::Builder->new();

$pdf->info(Producer => 'PDF::Builder Test Suite');
my %info = $pdf->info();
is($info{'Producer'}, 'PDF::Builder Test Suite', 'Check info string');

my $gfx = $pdf->page()->gfx();
$gfx->fillcolor('blue');

my $new = PDF::Builder->from_string($pdf->to_string());
%info = $new->info();
is($info{'Producer'}, 'PDF::Builder Test Suite', 'Check info string after save and reload');

##
## import_page
##

$pdf = $new;
$new = PDF::Builder->new();
my $form = $new->importPageIntoForm($pdf, 1);
#$form->{'-docompress'} = 0;  # not in API2 tests
delete $form->{'Filter'};
my $string = $new->to_string();
like($string, qr/0 0 1 rg/,
     q{Page imported by import_page contains content from original});

# Add a second page with a different page size

$new = PDF::Builder->from_string($string, 'compress' => 'none');
my $page = $pdf->page();
my $font = $pdf->corefont('Helvetica');
$page->mediabox(0, 0, 72, 144);
my $text = $page->text();
$text->font($font, 12);
$text->text('This is a test');
$pdf = PDF::Builder->from_string($pdf->to_string()); 
$form = $new->importPageIntoForm($pdf, 2);
#$form->{'-docompress'} = 0;  # not in API2 tests
delete $form->{'Filter'};

is(($form->bbox())[2], 72,
   q{Form bounding box is set from imported page});

$string = $new->to_string();

like($string, qr/\(This is a test\)/,
     q{Second imported page contains text});

# Page Numbering

$pdf = PDF::Builder->new('compress' => 'none');
$pdf->pageLabel(0, { 'style' => 'Roman' });

like($pdf->to_string(), qr{/PageLabels << /Nums \[ 0 << /S /R /St 1 >> \] >>},
     q{Page Numbering: Upper-case Roman Numerals});

$pdf = PDF::Builder->new('compress' => 'none');
$pdf->pageLabel(0, { 'style' => 'roman' });
like($pdf->to_string(), qr{/PageLabels << /Nums \[ 0 << /S /r /St 1 >> \] >>},
     q{Page Numbering: Upper-case Roman Numerals});

$pdf = PDF::Builder->new('compress' => 'none');
$pdf->pageLabel(0, { 'style' => 'Alpha' });
like($pdf->to_string(), qr{/PageLabels << /Nums \[ 0 << /S /A /St 1 >> \] >>},
     q{Page Numbering: Upper-case Alphabet Characters});

$pdf = PDF::Builder->new('compress' => 'none');
$pdf->pageLabel(0, { 'style' => 'alpha' });
like($pdf->to_string(), qr{/PageLabels << /Nums \[ 0 << /S /a /St 1 >> \] >>},
     q{Page Numbering: Lower-case Alphabet Characters});

$pdf = PDF::Builder->new('compress' => 'none');
$pdf->pageLabel(0, { 'style' => 'decimal' });
like($pdf->to_string(), qr{/PageLabels << /Nums \[ 0 << /S /D /St 1 >> \] >>},
     q{Page Numbering: Decimal Characters});

$pdf = PDF::Builder->new('compress' => 'none');
$pdf->pageLabel(0, { 'start' => 11 });
like($pdf->to_string(), qr{/PageLabels << /Nums \[ 0 << /S /D /St 11 >> \] >>},
     q{Page Numbering: Decimal Characters (implicit), starting at 11});

$pdf = PDF::Builder->new('compress' => 'none');
$pdf->pageLabel(0, { 'prefix' => 'Test' });
like($pdf->to_string(), qr{/PageLabels << /Nums \[ 0 << /P \(Test\) /S /D /St 1 >> \] >>},
     q{Page Numbering: Decimal Characters (implicit), with prefix});

## 
## to_string
##

$pdf = PDF::Builder->new('compress' => 'none');
$gfx = $pdf->page()->gfx();
$gfx->fillcolor('blue');

$string = $pdf->to_string();
like($string, qr/0 0 1 rg/,
     q{Stringify of newly-created PDF contains expected content});

my ($fh, $filename) = tempfile();
print $fh $string;
close $fh;

$pdf = PDF::Builder->open($filename);
$string = $pdf->to_string();
like($string, qr/0 0 1 rg/,
     q{Stringify of newly-opened PDF contains expected content});

##
## saveas with same filename
## (in response to bug 134993, introduced by 113516, not yet in PDF::Builder)
##

$pdf = PDF::Builder->new('compress' => 'none');
$gfx = $pdf->page()->gfx();
$gfx->fillcolor('blue');

($fh, $filename) = tempfile();
print $fh $pdf->to_string();
close $fh;

$pdf = PDF::Builder->open($filename, 'compress' => 'none');
$gfx = $pdf->page()->gfx();
$gfx->fillcolor('red');
$pdf->saveas($filename);

$pdf = PDF::Builder->open($filename, 'compress' => 'none');
$string = $pdf->to_string();
like($string, qr/0 0 1 rg/,
     q{saveas($opened_filename) contains original content});
like($string, qr/1 0 0 rg/,
     q{saveas($opened_filename) contains new content});

1;

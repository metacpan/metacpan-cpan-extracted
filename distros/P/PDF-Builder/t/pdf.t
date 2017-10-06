use Test::More tests => 12;

use warnings;
use strict;

use PDF::Builder;

my $pdf = PDF::Builder->new();

$pdf->info(Producer => 'PDF::Builder Test Suite');
my %info = $pdf->info();
is($info{'Producer'}, 'PDF::Builder Test Suite', 'Check info string');

my $gfx = $pdf->page->gfx();
$gfx->fillcolor('blue');

my $new = PDF::Builder->open_scalar($pdf->stringify());
%info = $new->info();
is($info{'Producer'}, 'PDF::Builder Test Suite', 'Check info string after save and reload');

##
## import_page
##

$pdf = $new;
$new = PDF::Builder->new();
my $form = $new->importPageIntoForm($pdf, 1);
$form->{'-docompress'} = 0;
delete $form->{'Filter'};
my $string = $new->stringify();
like($string, qr/0 0 1 rg/,
     q{Page imported by import_page contains content from original});

# Add a second page with a different page size

$new = PDF::Builder->open_scalar($string, '-compress' => 'none');
my $page = $pdf->page();
my $font = $pdf->corefont('Helvetica');
$page->mediabox(0, 0, 72, 144);
my $text = $page->text();
$text->font($font, 12);
$text->text('This is a test');
$pdf = PDF::Builder->open_scalar($pdf->stringify());
$form = $new->importPageIntoForm($pdf, 2);
$form->{'-docompress'} = 0;
delete $form->{'Filter'};

is(($form->bbox())[2], 72,
   q{Form bounding box is set from imported page});

$string = $new->stringify();

like($string, qr/\(This is a test\)/,
     q{Second imported page contains text});


# Page Numbering

$pdf = PDF::Builder->new('-compress' => 'none');
$pdf->pageLabel(0, { -style => 'Roman' });

like($pdf->stringify(), qr{/PageLabels << /Nums \[ 0 << /S /R >> \] >>},
     q{Page Numbering: Upper-case Roman Numerals});

$pdf = PDF::Builder->new('-compress' => 'none');
$pdf->pageLabel(0, { -style => 'roman' });
like($pdf->stringify(), qr{/PageLabels << /Nums \[ 0 << /S /r >> \] >>},
     q{Page Numbering: Upper-case Roman Numerals});

$pdf = PDF::Builder->new('-compress' => 'none');
$pdf->pageLabel(0, { -style => 'Alpha' });
like($pdf->stringify(), qr{/PageLabels << /Nums \[ 0 << /S /A >> \] >>},
     q{Page Numbering: Upper-case Alphabet Characters});

$pdf = PDF::Builder->new('-compress' => 'none');
$pdf->pageLabel(0, { -style => 'alpha' });
like($pdf->stringify(), qr{/PageLabels << /Nums \[ 0 << /S /a >> \] >>},
     q{Page Numbering: Lower-case Alphabet Characters});

$pdf = PDF::Builder->new('-compress' => 'none');
$pdf->pageLabel(0, { -style => 'decimal' });
like($pdf->stringify(), qr{/PageLabels << /Nums \[ 0 << /S /D >> \] >>},
     q{Page Numbering: Decimal Characters});

$pdf = PDF::Builder->new('-compress' => 'none');
$pdf->pageLabel(0, { -start => 11 });
like($pdf->stringify(), qr{/PageLabels << /Nums \[ 0 << /S /D /St 11 >> \] >>},
     q{Page Numbering: Decimal Characters (implicit), starting at 11});

$pdf = PDF::Builder->new('-compress' => 'none');
$pdf->pageLabel(0, { -prefix => 'Test' });
like($pdf->stringify(), qr{/PageLabels << /Nums \[ 0 << /P \(Test\) /S /D >> \] >>},
     q{Page Numbering: Decimal Characters (implicit), with prefix});


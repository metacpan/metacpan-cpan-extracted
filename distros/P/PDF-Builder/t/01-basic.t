use Test::More tests => 7;

use warnings;
use strict;

use PDF::Builder;

my $pdf = PDF::Builder->new();

isa_ok($pdf,
       'PDF::Builder',
       q{PDF::Builder->new() returns a PDF::Builder object});

my $page = $pdf->page();

isa_ok($page,
       'PDF::Builder::Page',
       q{$pdf->page() returns a PDF::Builder::Page object});

my $gfx = $page->gfx();

isa_ok($gfx,
       'PDF::Builder::Content',
       q{$pdf->gfx() returns a PDF::Builder::Content object});

my $text = $page->text();

isa_ok($text,
       'PDF::Builder::Content::Text',
       q{$pdf->text() returns a PDF::Builder::Content::Text object});


is($pdf->pages(),
   1,
   q{$pdf->pages() returns 1 on a one-page PDF});

# Insert a second page
$page = $pdf->page();

is($pdf->pages(),
   2,
   q{$pdf->pages() returns 2 after a second page is added});

# Open a PDF

$pdf = PDF::Builder->open('t/resources/sample.pdf');

isa_ok($pdf,
       'PDF::Builder',
       q{PDF::Builder->open() returns a PDF::Builder object});

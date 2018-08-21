#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;

use PDF::Builder;

# Create a PDF with an empty page
my $empty_page_pdf = PDF::Builder->new();
my $page = $empty_page_pdf->page();
$page->mediabox('Letter');

# Save and reopen the PDF
$empty_page_pdf = PDF::Builder->open_scalar($empty_page_pdf->stringify());

my $container_pdf = PDF::Builder->new();

# This dies through version 2.025.
eval {
    $container_pdf->importPageIntoForm($empty_page_pdf, 1);
};
ok(!$@, q{Calling importPageIntoForm using an empty page doesn't result in a crash});

1;

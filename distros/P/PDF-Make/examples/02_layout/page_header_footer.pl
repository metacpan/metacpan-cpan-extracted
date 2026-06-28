#!/usr/bin/perl
# Feature: Page Header and Footer
# Description: Demonstrates global page header/footer configuration and
#              page number placeholders across multiple pages.
# Output: corpus/feature_examples/02_layout/page_header_footer.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/02_layout');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/02_layout/page_header_footer',
    configure => {
        h1 => { font => { size => 22, line_height => 28, colour => '#1a1a2e' } },
        text => { font => { size => 10, colour => '#333' } },
    },
);

$pdf->add_page_header(
    show_page_num => 'right',
    page_num_text => 'Page {num}',
);

$pdf->add_page_footer(
    show_page_num => 'center',
    page_num_text => '- {num} -',
);

for my $n (1 .. 3) {
    $pdf->add_page(page_size => 'Letter', padding => 36)
        ->add_h1(text => "Header/Footer Demo - Page $n")
        ->add_text(text => 'Inspect top and bottom regions of each page to see the configured header and footer.')
        ->add_text(text => 'Headers/footers are configured once and applied to subsequent pages automatically.');
}

$pdf->save();
print "Created corpus/feature_examples/02_layout/page_header_footer.pdf\n";

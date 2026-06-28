#!/usr/bin/perl
# Feature: Table of Contents (TOC)
# Description: Demonstrates add_toc() with auto-collected headings and
#              clickable TOC entries generated from toc => 1 headings.
# Output: corpus/feature_examples/03_navigation/toc.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/03_navigation');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/03_navigation/toc',
    configure => {
        h1   => { font => { size => 24, line_height => 30, colour => '#1f2937' } },
        h2   => { font => { size => 14, line_height => 20, colour => '#374151' } },
        text => { font => { size => 10, family => 'Helvetica', colour => '#444' } },
        toc  => {
            title           => 'Table of Contents',
            title_font_args => { size => 22, colour => '#111827' },
            font_args       => { size => 10, colour => '#4b5563' },
            padding         => 4,
            level_indent    => 2.5,
        },
    },
);

# TOC placeholder page must come first
$pdf->add_page(page_size => 'Letter')->add_toc();

$pdf->add_page()
    ->add_h1(text => 'Introduction', toc => 1)
    ->add_text(text => 'This page introduces the navigation examples and TOC rendering.')
    ->add_h2(text => 'Why TOC Matters', toc => 1)
    ->add_text(text => 'TOC entries are clickable and jump directly to their headings.');

$pdf->add_page()
    ->add_h1(text => 'Core Concepts', toc => 1)
    ->add_h2(text => 'Headings Collection', toc => 1)
    ->add_text(text => 'Any heading with toc => 1 is included in the generated TOC.')
    ->add_h2(text => 'Dot Leaders and Page Numbers', toc => 1)
    ->add_text(text => 'TOC rows include dot leaders and right-aligned page numbers.');

$pdf->add_page()
    ->add_h1(text => 'Conclusion', toc => 1)
    ->add_text(text => 'Use this pattern for reports, manuals, and technical guides.');

$pdf->save();
print "Created corpus/feature_examples/03_navigation/toc.pdf\n";

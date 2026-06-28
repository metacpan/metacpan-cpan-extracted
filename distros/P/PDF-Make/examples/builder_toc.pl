#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use PDF::Make::Builder;

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/builder_toc',
    configure => {
        h1 => { font => { colour => '#2c3e50', size => 26, line_height => 30 } },
        h2 => { font => { colour => '#2980b9', size => 18, line_height => 22 } },
        h3 => { font => { colour => '#27ae60', size => 14, line_height => 18 } },
        text => { font => { size => 10, family => 'Helvetica', colour => '#333' } },
        toc => {
            title => 'Table of Contents',
            title_font_args => { size => 24, colour => '#2c3e50' },
            title_padding => 20,
            font_args => { size => 10, colour => '#555' },
            padding => 3,
        },
    }
);

# Page 1: TOC placeholder
$pdf->add_page(page_size => 'Letter')
    ->add_toc();

# Page 2: Introduction
$pdf->add_page()
    ->add_h1(text => 'Introduction', toc => 1)
    ->add_text(text => 'This document demonstrates the PDF::Make::Builder table of '
                     . 'contents feature. Headings marked with toc => 1 are automatically '
                     . 'collected and rendered on the TOC page with dot leaders and page '
                     . 'numbers. The TOC supports multiple heading levels.')
    ->add_h2(text => 'Background', toc => 1)
    ->add_text(text => 'PDF::Make is a from-scratch PDF generation library for Perl. '
                     . 'The Builder layer provides a high-level API with automatic '
                     . 'word-wrapping, font management, and coordinate translation. '
                     . 'It sits on top of the low-level Canvas operators.')
    ->add_h2(text => 'Architecture', toc => 1)
    ->add_text(text => 'Builder uses Object::Proto for call-checker-optimised typed '
                     . 'slots. Each component - Text, Shape, Font, Page - is a separate '
                     . 'Object::Proto class with typed properties and method chaining.');

# Page 3: Features
$pdf->add_page()
    ->add_h1(text => 'Features', toc => 1)
    ->add_h2(text => 'Typography', toc => 1)
    ->add_text(text => 'Builder supports all 14 standard PDF fonts across three '
                     . 'families: Helvetica, Times, and Courier. Each family includes '
                     . 'regular, bold, italic, and bold-italic variants.')
    ->add_h3(text => 'Word Wrapping', toc => 1)
    ->add_text(text => 'Text is automatically wrapped to fit within the available '
                     . 'page width. The word-wrap algorithm uses approximate character '
                     . 'widths for each Standard 14 font to calculate line breaks.')
    ->add_h3(text => 'Alignment', toc => 1)
    ->add_text(text => 'Text can be aligned left, center, or right within its '
                     . 'container. Each line is positioned independently using '
                     . 'absolute text matrix positioning.')
    ->add_h2(text => 'Shapes', toc => 1)
    ->add_text(text => 'Builder provides line, box, circle, ellipse, and pie/arc '
                     . 'shapes. Circles and ellipses are approximated using four '
                     . 'cubic Bezier curves.');

# Page 4: API Reference
$pdf->add_page()
    ->add_h1(text => 'API Reference', toc => 1)
    ->add_h2(text => 'Document Lifecycle', toc => 1)
    ->add_text(text => 'Create a Builder, add pages and content via chained add_* '
                     . 'calls, then call save() to finalize. Headers and footers '
                     . 'are rendered at save time across all pages.')
    ->add_h2(text => 'Page Management', toc => 1)
    ->add_text(text => 'Pages support configurable sizes (A4, Letter, Legal, etc.), '
                     . 'multi-column layouts, padding, and optional headers/footers. '
                     . 'Content automatically flows to the next page when overflow '
                     . 'is enabled.')
    ->add_h2(text => 'Content Methods', toc => 1)
    ->add_text(text => 'All add_* methods return $self for chaining: add_text, '
                     . 'add_h1 through add_h6, add_line, add_box, add_circle, '
                     . 'add_ellipse, add_pie, add_image, add_toc.');

# Render TOC on page 1
$pdf->open_page(1);
$pdf->save();

print "Wrote corpus/builder_toc.pdf\n";

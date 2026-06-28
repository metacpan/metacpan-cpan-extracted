#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 'lib';
use PDF::Make::Builder;

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/builder_demo',
    configure => {
        h1 => { font => { colour => '#336699', size => 28, line_height => 32 } },
        h2 => { font => { colour => '#3498db', size => 18, line_height => 22 } },
        text => { font => { size => 11, family => 'Helvetica', colour => '#333' } },
    }
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'PDF::Make::Builder Demo')
    ->add_text(text => 'This document was generated using the high-level Builder API. '
                     . 'Builder wraps the low-level PDF::Make Canvas operators with '
                     . 'automatic word-wrapping, font management, and coordinate '
                     . 'translation. All add_ methods return $self for chaining.')
    ->add_h2(text => 'Typography')
    ->add_text(text => 'The quick brown fox jumps over the lazy dog. '
                     . 'Pack my box with five dozen liquor jugs. '
                     . 'How vexingly quick daft zebras jump.',
              font => { family => 'Helvetica', size => 12 })
    ->add_text(text => 'The quick brown fox jumps over the lazy dog. '
                     . 'Pack my box with five dozen liquor jugs.',
              font => { family => 'Times', size => 12 })
    ->add_text(text => 'The quick brown fox jumps over the lazy dog.',
              font => { family => 'Courier', size => 10 })
    ->add_h2(text => 'Shapes')
    ->add_box(fill_colour => '#3498db', w => 120, h => 50)
    ->add_box(fill_colour => '#2ecc71', w => 120, h => 50)
    ->add_box(fill_colour => '#e74c3c', w => 120, h => 50)
    ->add_h2(text => 'Lines')
    ->add_line(fill_colour => '#333', type => 'solid')
    ->add_text(text => 'Solid line')
    ->add_line(fill_colour => '#3498db', type => 'dashed')
    ->add_text(text => 'Dashed line')
    ->add_line(fill_colour => '#2ecc71', type => 'dots')
    ->add_text(text => 'Dotted line')
    ->add_h2(text => 'Long Text with Word Wrap')
    ->add_text(text => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                     . 'Sed do eiusmod tempor incididunt ut labore et dolore magna '
                     . 'aliqua. Ut enim ad minim veniam, quis nostrud exercitation '
                     . 'ullamco laboris nisi ut aliquip ex ea commodo consequat. '
                     . 'Duis aute irure dolor in reprehenderit in voluptate velit '
                     . 'esse cillum dolore eu fugiat nulla pariatur. Excepteur sint '
                     . 'occaecat cupidatat non proident, sunt in culpa qui officia '
                     . 'deserunt mollit anim id est laborum.')
    ->save();

print "Wrote corpus/builder_demo.pdf\n";

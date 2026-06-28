#!/usr/bin/perl
# Feature: Styled Text
# Description: Demonstrates text styling including bold, italic, colors, and font sizes.
#              Shows how to apply multiple styles to text elements.
# Output: corpus/feature_examples/01_basics/styled_text.pdf

use strict;
use warnings;
use lib 'lib';
use PDF::Make::Builder;

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/01_basics/styled_text',
);

$pdf->add_page(page_size => 'Letter')
    ->add_text(text => 'Normal text at default size and color.')
    ->add_text(text => 'Bold text stands out.',
               font => { bold => 1 })
    ->add_text(text => 'Italic text is slanted.',
               font => { italic => 1 })
    ->add_text(text => 'Red colored text.',
               font => { colour => '#ff0000' })
    ->add_text(text => 'Blue colored text.',
               font => { colour => '#0000ff' })
    ->add_text(text => 'Larger text at 14pt.',
               font => { size => 14 })
    ->add_text(text => 'Bold blue text at 16pt.',
               font => { bold => 1, colour => '#0080ff', size => 16 })
    ->add_text(text => 'Back to normal.');

$pdf->save();
print "Created corpus/feature_examples/01_basics/styled_text.pdf\n";

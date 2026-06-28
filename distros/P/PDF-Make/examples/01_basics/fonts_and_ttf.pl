#!/usr/bin/perl
# Feature: Fonts and TTF
# Description: Demonstrates using system fonts, changing font families, and loading
#              TrueType fonts (.ttf files) for custom typography.
# Output: corpus/feature_examples/01_basics/fonts_and_ttf.pdf

use strict;
use warnings;
use lib 'lib';
use PDF::Make::Builder;

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/01_basics/fonts_and_ttf',
);

$pdf->add_page(page_size => 'Letter')
    ->add_text(text => 'Default Helvetica font.')
    ->add_text(text => 'Times Roman font (serif).',
               font => { family => 'Times' })
    ->add_text(text => 'Courier font (monospace).',
               font => { family => 'Courier' })
    ->add_text(text => 'Helvetica Bold (system font with weight).',
               font => { family => 'Helvetica', bold => 1 })
    ->add_text(text => 'Back to Helvetica.')
    ->add_h2(text => 'Font Sizes');

for my $size (8, 10, 12, 14, 16, 18, 20) {
    $pdf->add_text(text => "This is $size point text.",
                   font => { size => $size }, spacing => $size > 12 ? 3 : 0);
}

$pdf->add_h2(text => 'Spacing and Padding')
    ->add_text(
        text    => 'This paragraph uses padding => 8 and spacing => 3. '
                 . 'Padding adds inset around the text block, and spacing adds '
                 . 'extra vertical distance between wrapped lines for readability.',
        w       => 360,
        padding => 8,
        spacing => 3,
        font    => { size => 11 },
    );

$pdf->add_h2(text => 'Font Families')
    ->add_text(text => 'PDF::Make supports system fonts and TTF file loading for custom typography.')
    ->add_text(text => 'Available system fonts include: Helvetica, Times, Courier, Symbol, and more.');

$pdf->save();
print "Created corpus/feature_examples/01_basics/fonts_and_ttf.pdf\n";

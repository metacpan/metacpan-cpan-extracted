#!/usr/bin/perl
# Feature: Overflow and Paging
# Description: Demonstrates overflow => 1 behavior that automatically creates
#              new pages when text exceeds available page space.
# Output: corpus/feature_examples/02_layout/overflow_and_paging.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/02_layout');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/02_layout/overflow_and_paging',
    configure => {
        h1   => { font => { size => 22, line_height => 28, colour => '#1a1a2e' } },
        text => { font => { size => 10, family => 'Helvetica', colour => '#333' } },
    },
);

my $paragraph = 'Overflow mode lets long content continue to new pages automatically. '
              . 'This keeps example code simple while producing readable multi-page output. ';

$pdf->add_page(page_size => 'Letter', padding => 36)
    ->add_h1(text => 'Automatic Overflow and Paging')
    ->add_text(
        text     => $paragraph x 280,
        overflow => 1,
        spacing  => 1,
    );

$pdf->save();
print "Created corpus/feature_examples/02_layout/overflow_and_paging.pdf\n";

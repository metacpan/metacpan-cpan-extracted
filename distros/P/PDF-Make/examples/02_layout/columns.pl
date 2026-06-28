#!/usr/bin/perl
# Feature: Columns
# Description: Demonstrates multi-column page flow. Inspect how long text
#              automatically continues from the first column into the next.
# Output: corpus/feature_examples/02_layout/columns.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/02_layout');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/02_layout/columns',
    configure => {
        h1   => { font => { size => 24, line_height => 30, colour => '#1a1a2e' } },
        text => { font => { size => 10, family => 'Helvetica', colour => '#333' } },
    },
);

my $lorem = 'This example demonstrates automatic text flow in columns. '
          . 'When one column reaches the bottom margin, content continues '
          . 'in the next column without manual positioning. ';

$pdf->add_page(page_size => 'Letter', padding => 36, columns => 2)
    ->add_h1(text => 'Two-Column Flow')
    ->add_text(
        text     => $lorem x 120,
        overflow => 1,
        spacing  => 1,
    );

$pdf->save();
print "Created corpus/feature_examples/02_layout/columns.pdf\n";

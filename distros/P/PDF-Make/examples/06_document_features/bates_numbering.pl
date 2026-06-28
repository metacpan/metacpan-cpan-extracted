#!/usr/bin/perl
# Feature: Bates Numbering
# Description: Demonstrates Bates-style sequential page numbering used in legal
#              and regulatory document production. Each page gets a unique
#              identifier in the header or footer region.
# Output: corpus/feature_examples/06_document_features/bates_numbering.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/06_document_features');

my $prefix   = 'DOC';
my $start_no = 1001;

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/06_document_features/bates_numbering',
);

# Add a footer that renders the Bates number bottom-right on every page.
# The ctx helper takes care of font loading, alignment, and coords; we
# just supply the formatted number.
$pdf->add_page_footer(
    h  => 30,
    cb => sub {
        my (undef, undef, %args) = @_;
        my $ctx   = $args{ctx};
        my $bates = sprintf('%s-%06d', $prefix, $start_no + $ctx->num - 1);
        $ctx->text(
            text  => $bates,
            align => 'right',
            font  => { size => 8, colour => '#666' },
        );
    },
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Bates Numbering Example')
    ->add_text(text => 'Each page of this document carries a unique Bates number '
                     . 'in the bottom-right corner.')
    ->add_text(text => "Prefix: $prefix, starting at: $start_no");

$pdf->add_page
    ->add_h2(text => 'Page Two')
    ->add_text(text => 'This page should show ' . sprintf('%s-%06d', $prefix, $start_no + 1));

$pdf->add_page
    ->add_h2(text => 'Page Three')
    ->add_text(text => 'This page should show ' . sprintf('%s-%06d', $prefix, $start_no + 2));

$pdf->save();
print "Created corpus/feature_examples/06_document_features/bates_numbering.pdf\n";

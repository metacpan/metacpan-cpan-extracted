#!/usr/bin/perl
# Feature: Text Extraction (batch pages)
# Description: Attempts extraction across multiple pages for several PDFs.

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use PDF::Make::Builder;

my $pdf = PDF::Make::Builder->new(file_name => 't/fixtures/_unused_extract_demo.pdf');

my %targets = (
    't/fixtures/builder_demo.pdf'     => [0, 1, 2],
    't/fixtures/builder_enhanced.pdf' => [0, 1, 2],
    't/fixtures/two_column_test.pdf'  => [0],
);

for my $file (sort keys %targets) {
    print "\n=== $file ===\n";

    for my $page_index (@{ $targets{$file} }) {
        my $text = eval { $pdf->extract_text($file, $page_index) };
        if ($@) {
            print "  page " . ($page_index + 1) . ": failed ($@)\n";
            next;
        }

        my $preview = $text // '';
        $preview =~ s/\s+/ /g;
        $preview =~ s/^\s+|\s+$//g;
        $preview = substr($preview, 0, 120);

        print "  page " . ($page_index + 1) . ": "
            . (length($preview) ? $preview : '(no text extracted)') . "\n";
    }
}

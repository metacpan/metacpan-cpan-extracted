#!/usr/bin/perl
# Feature: Text Extraction (plain)
# Description: Extracts plain text from page 1 of a few sample PDFs.

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use PDF::Make::Builder;

my $pdf = PDF::Make::Builder->new(file_name => 't/fixtures/_unused_extract_demo.pdf');

my @files = (
    't/fixtures/hello_world.pdf',
    't/fixtures/styled_demo.pdf',
    't/fixtures/layout_demo.pdf',
);

for my $file (@files) {
    print "\n=== $file (page 1) ===\n";
    my $text = eval { $pdf->extract_text($file, 0) };
    if ($@) {
        print "Extraction failed: $@\n";
        next;
    }
    $text =~ s/\s+/ /g;
    $text =~ s/^\s+|\s+$//g;
    print(length($text) ? "$text\n" : "(no text extracted)\n");
}

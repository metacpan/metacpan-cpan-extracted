#!/usr/bin/perl
# Feature: Structured Text Extraction
# Description: Extracts text blocks/words with coordinates from sample PDFs.

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use PDF::Make::Builder;

my $pdf = PDF::Make::Builder->new(file_name => 't/fixtures/_unused_extract_demo.pdf');

my @files = (
    't/fixtures/hello_world.pdf',
    't/fixtures/ligature_test.pdf',
    't/fixtures/invisible_text_test.pdf',
);

for my $file (@files) {
    print "\n=== $file (page 1) ===\n";

    my $res = eval { $pdf->extract_structured($file, page => 0, invisible => 1) };
    if ($@) {
        print "Extraction failed: $@\n";
        next;
    }

    my $blocks = $res->data || [];
    my $shown = 0;

    for my $block (@$blocks) {
        my $lines = $block->{lines} || [];
        for my $line (@$lines) {
            my $words = $line->{words} || [];
            my $txt = join ' ', map { $_->{text} // '' } @$words;
            $txt =~ s/\s+/ /g;
            $txt =~ s/^\s+|\s+$//g;
            next unless length $txt;

            my $x = defined $line->{x0} ? $line->{x0} : '?';
            my $y = defined $line->{baseline} ? $line->{baseline} : (defined $line->{y0} ? $line->{y0} : '?');
            print sprintf("  [%s, %s] %s\n", $x, $y, $txt);

            last if ++$shown >= 12;
        }
        last if $shown >= 12;
    }

    print "  (no visible text items)\n" if !$shown;
}

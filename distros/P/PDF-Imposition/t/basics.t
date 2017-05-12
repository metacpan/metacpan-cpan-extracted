#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec::Functions;
use PDF::Imposition;
use Data::Dumper;
use PDF::API2;

plan tests => 17;

my $sample = catfile(t => "sample2e.pdf");
my $outsample = catfile(t => "sample2e-imp.pdf");
if (-f $outsample) {
    unlink $outsample or die "cannot unlink $outsample $!"
}
my $imposer = PDF::Imposition->new(file => $sample);

is($imposer->total_pages, 3, "pages ok");
is($imposer->orig_width, 595.28, "width ok");
is($imposer->orig_height, 841.89, "height ok");
is_deeply($imposer->dimensions, {
                                 w => 595.28,
                                 h => 841.89,
                                }, "dimension ok");


my $seq = $imposer->imposer->page_sequence_for_booklet(24);
$seq = $imposer->imposer->page_sequence_for_booklet(18,16);
format_seq($seq);
ok (!$imposer->signature, "No signature set yet");
$imposer->signature(4);
is($imposer->computed_signature, 4, "signature picked up");

for (6, 7, 9, 11, 17) {
    eval {
        my $imp = PDF::Imposition->new(schema => '2up',
                                       signature => $_);
        my $computed = $imp->computed_signature;
    };
    ok($@, "signature of $_ not accepted");
}

$imposer->signature(8);
is($imposer->computed_signature, 8, "signature picked up");


ok($imposer->imposer->in_pdf_obj, "in object ok");
ok($imposer->imposer->out_pdf_obj, "out object ok");
ok($imposer->imposer->_tmp_dir, "Temp directory is " . $imposer->imposer->_tmp_dir);
is($imposer->impose, $outsample);
ok(-f $outsample, "output file $outsample created");
unlink $outsample or die "Couldn't unlink $outsample $!";


sub format_seq {
    my $sequence = shift;
    my @seq = @$sequence;
    while (my $page = shift(@seq)) {
        printf (' [%3s] [%3s]', $page->[0] || " * ", $page->[1] || " * ");
        print "\n";
    }
}


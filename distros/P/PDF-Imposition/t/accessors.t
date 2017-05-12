#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec::Functions;
use PDF::Imposition;
use Data::Dumper;
use Try::Tiny;

plan tests => 16;

my $pdfi = PDF::Imposition->new;

$pdfi->file(catfile(t => "sample2e.pdf"));
$pdfi->cover(1);
$pdfi->suffix("-test");

testaccessors($pdfi);

$pdfi = PDF::Imposition->new(
                             file => catfile(t => "sample2e.pdf"),
                             cover => 1,
                             suffix => "-test",
                            );

testaccessors($pdfi);

$pdfi = PDF::Imposition->new(
                             file => catfile(t => "sample2e.pdf"),
                             cover => 1,
                             suffix => "-test",
                             outfile => "prova_pdf.pdf"
                            );

is($pdfi->outfile, "prova_pdf.pdf");

$pdfi = PDF::Imposition->new;

my $err = 0;
try {
    $pdfi->file("xxx");
} catch {
    $err++;
    diag $_;
};
ok($err, "non existent file raises exception");

$err = 0;
try {
    $pdfi->file("");
} catch {
    $err++;
    diag $_;
};
ok($err, "empty string raises exception");


$err = 0;
try {
    $pdfi->file("t");
} catch {
    $err++;
    diag $_;
};
ok($err, "directory raises exception");


$err = 0;
$pdfi->file("README.pdf");

try {
    $pdfi->impose;
} catch {
    diag $_;
    $err++;
};
ok($err, "not a pdf raises exception when calling ->impose");

{
    my $imposer = PDF::Imposition->new(file => catfile(t => "sample2e.pdf"),
                                       suffix => '-test',
                                       paper => 'a3',
                                       cover => 1);
    $imposer->impose;
    ok (-f catfile(t => "sample2e-test.pdf"), "output produced");
    unlink catfile(t => "sample2e-test.pdf") or die $!;
}


sub testaccessors {
    my $pdf = shift;
    # print Dumper($pdf);
    ok($pdf->imposer->output_filename, "outfile ok") and $pdf->outfile;
    is($pdf->imposer->output_filename, catfile(t => "sample2e-test.pdf"), "sample2-test.pdf");
    is($pdf->cover, 1, "cover is true");
    is($pdf->suffix, "-test", "suffix exists");
    $pdf->outfile("test.pdf");
    is($pdf->outfile, "test.pdf", "outfile overwrites");
}


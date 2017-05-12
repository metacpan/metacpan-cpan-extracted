#!/usr/bin/env perl

use strict;
use warnings;
use PDF::Imposition;
use File::Spec::Functions;
use Test::More;
plan tests => 1;

my $input = catfile(t => "pdfv16.pdf");
my $outputdir = catdir(t => "output");
unless (-d $outputdir) {
    mkdir $outputdir or die "Cannot create $outputdir $!";
}
my $output = catfile($outputdir, "pdfv16-imp.pdf");
if (-f $output) {
    unlink $output or die "Couldn't unlink $output $!";
}
my $imposer = PDF::Imposition->new(file => $input);
$imposer->outfile($output);
$imposer->impose;
ok((-f $output), "$output created");
# unlink $output or die "Couldn't unlink $output $!";

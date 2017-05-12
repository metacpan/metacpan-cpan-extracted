#!perl
use utf8;
use strict;
use warnings;

use Test::More tests => 56;
use Data::Dumper;
use PDF::API2;
use PDF::Cropmarks;
use File::Spec::Functions qw/catfile catdir/;
use File::Temp;

my @out;

my $input = catfile(qw/t test-input.pdf/);
my $outdir = catdir(qw/t output/);
mkdir $outdir unless -d $outdir;

foreach my $spec ({
                    name => "plain",
                    title => "Title paper is a4",
                    paper => 'a4',
                    expected => 12,
                   },
                   {
                    name => "a6-not-visible",
                    title => "Title paper is a6",
                    paper => 'a6',
                    expected => 12,
                   },
                   {
                    name => 'no-top-no-inner-two-side',
                    top => 0,
                    inner => 0,
                    bottom => 1,
                    outer => 1,
                    twoside => 1,
                    cropmark_length => '10mm',
                    cropmark_offset => '1mm',
                    font_size => '10pt',
                    signature => 1,
                    paper_thickness => '1mm',
                    expected => 12,
                    paper => 'a4',
                   },
                   {
                    name => 'no-bottom-no-outer-sig-16-two-side-letter',
                    top => 1,
                    inner => 1,
                    bottom => 0,
                    outer => 0,
                    twoside => 1,
                    cropmark_length => '1cm',
                    cropmark_offset => '8pt',
                    font_size => '8pt',
                    signature => 16,
                    expected => 16,
                    paper => 'letter',
                   },
                   {
                    name => 'no-top-no-inner-sig-4-one-side',
                    top => 0,
                    inner => 0,
                    bottom => 1,
                    outer => 1,
                    twoside => 0,
                    cropmark_length => '1in',
                    cropmark_offset => '1MM',
                    font_size => '10pt',
                    signature => 4,
                    expected => 12,
                    paper => 'a4'
                   },
                   {
                    name => 'no-inner-sig-8-two-side',
                    top => 1,
                    inner => 0,
                    bottom => 1,
                    outer => 1,
                    twoside => 1,
                    cropmark_length => '1in',
                    cropmark_offset => '1MM',
                    font_size => '10pt',
                    signature => 8,
                    expected => 16,
                    paper => 'a4',
                    cover => 1,
                   },
                   {
                    name => 'no-bottom-no-inner-one-side-b4',
                    top => 1,
                    inner => 1,
                    bottom => 0,
                    outer => 0,
                    twoside => 0,
                    cropmark_length => '0.5IN',
                    cropmark_offset => '1MM',
                    font_size => '10PT',
                    expected => 12,
                    paper => 'b4',
                   }) {
    my $name = delete $spec->{name};
    my $expected = delete $spec->{expected};
    die "Missing name" unless $name;
    my $output = catfile($outdir, $name . '.pdf');
    unlink $output if -f $output;
    ok (! -f $output, "No $output found");
    my $cropper = PDF::Cropmarks->new(input => $input,
                                      output => $output,
                                      %$spec,
                                     );
    ok $cropper->in_pdf_object;
    ok $cropper->out_pdf_object;
    ok $cropper->_tmpdir;
    ok (-d $cropper->_tmpdir, "Tmpdir exists : ". $cropper->_tmpdir);
    ok $cropper->add_cropmarks;
    ok (-f $output, "$output exists");
    my $pdf = PDF::API2->open($output);
    my $count = $pdf->pages;
    is($count, $expected, "Found $expected pages");
    # we can't really test much without looking at the output...
    # diag "Output left in $output";
    push @out, $output;
}


diag "Output:\n" . join("\n", @out);


#!perl

use strict;
use warnings;
use Test::More tests => 12;
use File::Spec::Functions;
use PDF::API2;
use PDF::Cropmarks;
use File::Temp;

my $missing_pdftotext = system('pdftotext', '-v');
my $wd = File::Temp->newdir(CLEANUP => !$ENV{AMW_NOCLEANUP});
my $outdir = catdir(qw/t output/);
mkdir $outdir unless -d $outdir;
diag "Using $wd for output";

foreach my $spec ({
                   name => 'cover',
                   pages => 14,
                   expected => 16,
                   sequence => [ [1], [2], [3], [4], [5], [6], [7], [8],
                                 [9], [10], [11], [12], [13], [], [], [14] ],
                   signature => 16,
                   cover => 1,
                  },
                  {
                   name => 'no-cover',
                   pages => 14,
                   expected => 16,
                   sequence => [ [1], [2], [3], [4], [5], [6], [7], [8],
                                 [9], [10], [11], [12], [13], [14], [], [] ],
                   signature => 16,
                   cover => 0,
                  }) {
    my $pdf = create_pdf(catfile($wd, "$spec->{name}-in.pdf"), 14);
    diag "Creating $pdf";
    my $out = catfile($outdir, "$spec->{name}-out.pdf");
    unlink $out if -f $out;
    ok (! -f $out, "No $out found");
    ok (-f $pdf, "$pdf is ok");
    my $cropper = PDF::Cropmarks->new(input => $pdf,
                                      output => $out,
                                      paper => '400pt:500pt',
                                      signature => $spec->{signature},
                                      paper_thickness => '5mm',
                                      twoside => 1,
                                      cover => $spec->{cover});
    ok ($cropper, "Object created");
    $cropper->add_cropmarks;
    ok (-f $out, "Found $out");
  SKIP: {
        skip "pdftotext is not available", 1 if $missing_pdftotext;
        my $pages_got = extract_pages(extract_pdf($out));
        is_deeply($pages_got, $spec->{sequence},
                  "Sequence correct");
    }
    my $test_pdf = PDF::API2->open($out);
    my $page_count = $test_pdf->pages;
    $test_pdf->end;
    is($page_count, $spec->{expected}, "$out has $spec->{expected} pages");

}




sub create_pdf {
    my ($pdf, $pages) = @_;
    die unless $pdf && $pages;
    my $pdfobj = PDF::API2->new();
    my ($x, $y) = (300,400);
    $pdfobj->mediabox($x, $y);
    my $font = $pdfobj->corefont('Helvetica-Bold');
    for my $p (1.. $pages) {
        my $page = $pdfobj->page();
        my $text = $page->text();
        $text->font($font, 20);
        $text->translate($x / 2, $y / 2);
        $text->text_center("XXPg $p XX");
        my $line = $page->gfx;
        $line->linewidth(1);
        $line->strokecolor('black');
        $line->rectxy(1, 1, $x - 1, $y -1);
        $line->stroke;
    }
    $pdfobj->saveas($pdf);
    return $pdf;
}

sub extract_pdf {
    my $pdf = shift;
    my $txt = $pdf;
    $txt =~ s/\.pdf$/.txt/;
    system(pdftotext => $pdf) == 0 or die 'pdftotext failed $?';
    local $/ = undef;
    open (my $fh, '<', $txt) or die "cannot open $txt $!";
    my $ex = <$fh>;
    close $fh;
    return $ex;
}

sub extract_pages {
    my $rawtext = shift;
    # split at ^L
    my @pages = split /\x{0C}/, $rawtext;
    my @out;
    # print Dumper(\@pages);
    foreach my $p (@pages) {
        my @nums;
        # this is (of course) very fragile;

        while ($p =~ m/\s*(XXPg (\d+))\s*XX/gs) {
            push @nums, $2;
        }
        push @out, \@nums;
    }
    return \@out;
}

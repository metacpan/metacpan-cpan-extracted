#!perl

use strict;
use warnings;
use Test::More;
use PDF::Imposition;
use PDF::API2;
use File::Spec::Functions;
use File::Temp;
use File::Path qw/remove_tree make_path/;
use Data::Dumper;

my @schemas = PDF::Imposition->available_schemas;

plan tests => @schemas * 9;

my $missing_pdftotext = system('pdftotext', '-v');

my $outputdir = catdir("t", "output", $PDF::Imposition::VERSION . '-cropmarks');
if (-d $outputdir) {
    remove_tree($outputdir);
}
make_path($outputdir);

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
}

my %enabled = (
               '1x1'              => { cover => 1,
                                       pages => 5,
                                       signature => 8,
                                       expected => 8,
                                     },
               '2up'              => { cover => 1,
                                       pages => 9,
                                       expected => 6,
                                     },
               '2down'            => { cover => 1,
                                       pages => 9,
                                       expected => 6,
                                     },
               '2side'            => { pages => 5,
                                       expected => 4,
                                     },
               '2x4x2'            => { pages => 19,
                                       expected => 8, # 8 * 4 = 32, sig is 16
                                     },
               '1x4x2cutfoldbind' => { cover => 1,
                                       pages => 11,
                                       expected => 4,
                                     },
               '4up'              => { cover => 1,
                                       pages => 9,
                                       expected => 4,
                                     },
               '1repeat2side'     => { pages => 3, expected => 3 },
               '1repeat2top'      => { pages => 3, expected => 3 },
               '1repeat4'         => { pages => 3, expected => 3 },
               'ea4x4'            => { pages => 29, expected => 8 },
               '1x8x2'            => { pages => 29, expected => 4 },
              );

foreach my $schema (@schemas) {
    diag "Testing $schema";
    my $spec = $enabled{$schema};
    my $in_pdf =  catfile($outputdir, $schema . '-input.pdf');
    unlink $in_pdf if -f $in_pdf;
    ok (! -f $in_pdf, "No original $in_pdf found");
    if ($spec) {
        if (my $pages = $spec->{pages}) {
            diag "Creating $in_pdf";
            create_pdf($in_pdf, $pages);
        }
        else {
            die "Specification is missing the pages key!";
        }
    }

    foreach my $cover (0..1) {
        my $out = catfile($outputdir, $schema . ($cover ? '-cover' : '')
                          . '-cropmarks.pdf');
        unlink $out if $out;
        diag "Testing cropmarks against $schema, cover: $cover imposing $in_pdf";
        ok (! -f $out, "Directory clean, no $out");
      SKIP: {
            skip "$schema " . ($cover ? "with cover" : "")
              . " test disabled", 1 unless $spec;

            skip "$schema doesn't need cover testing", 1
              if $cover && !$spec->{cover};

            my $imposer = PDF::Imposition->new(schema => $schema,
                                               file => $in_pdf,
                                               outfile => $out,
                                               cover => $cover,
                                               paper => "400pt:500pt",
                                               paper_thickness => '1mm',
                                               ($spec->{signature} ? (signature => $spec->{signature}) : ()),
                                              );
            $imposer->impose;
            ok (-f $out, "$out produced");
        }
      SKIP: {
            skip "$out not produced, pdf parsing not required", 1 unless -f $out;
            skip "no pdftotext available, skipping", 1 if $missing_pdftotext;
            my $pages_got = extract_pages(extract_pdf($out));
            is_deeply($pages_got, [ 1 .. $spec->{pages} ], "All pages ok");
        }
      SKIP: {
            skip "$out not produced, pdf parsing not required", 1 unless -f $out;
            my $test_pdf = PDF::API2->open($out);
            my $page_count = $test_pdf->pages;
            $test_pdf->end;
            is($page_count, $spec->{expected}, "Physical pages are $spec->{expected}");
        }
    }
    unlink $in_pdf if -f $in_pdf;
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
    my %pages;
    while ($rawtext =~ m/\s*(XXPg\s*(\d+)\s*XX)\s*/gs) {
        $pages{$2} = 1;
    }
    return [ sort { $a <=> $b } keys %pages ];
}

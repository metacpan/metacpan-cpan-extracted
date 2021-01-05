use strict;
use warnings;
use Test::More tests => 157;
use File::Temp;
use File::Spec::Functions;
use File::Basename;
use File::Copy;
use PDF::Imposition;
use PDF::API2;
use Data::Dumper;

my $pdftotext = system('pdftotext', '-v');
my $skipex;
my $testdir = File::Temp->newdir(CLEANUP => 1);
my $outputdir = catdir("t", "output", $PDF::Imposition::VERSION);
unless (-d $outputdir) {
    mkdir catdir("t", "output") unless -d catdir("t", "output");
    mkdir $outputdir or die "Cannot create $outputdir $!";
}

if ($pdftotext != 0) {
    $skipex = 1;
    diag "It appears that pdftotext is not available.";
    diag "I'm just testing that the imposer produces something";
    diag "For a full visual testing, you have to look at the files left" .
      " in $outputdir";
    diag "Anyway, some testing is way better than no test at all";
} 

diag "Using $testdir as test directory";
unless (-d $testdir) {
    mkdir $testdir or die "cannot create $testdir => $!";
}

{
    my $pdffile = create_pdf("1x1-6", 1..6);
    my $imp = PDF::Imposition->new(file => $pdffile, signature => '0-20',
                                   pages_per_sheet => 4,
                                   title => 'This one has a title',
                                   schema => '1x1',);
    $imp->cover(1);
    $imp->impose;

    test_is_deeply($imp,
                   [ [1], [2], [3], [4], [5], [], [], [6] ],
                   "Imposing 6 pages OK", 6);
    is ($imp->computed_signature, 8, "Signature computed ok");
}

{
    my $pdffile = create_pdf("1x1-6-nosig", 1..6);
    my $imp = PDF::Imposition->new(file => $pdffile, cover => 1,
                                   pages_per_sheet => 4,
                                   schema => '1x1',
                                  );
    $imp->impose;
    test_is_deeply($imp,
                   [ [1], [2], [3], [4], [5], [], [], [6] ],
                   "Imposing 6 pages OK", 6);
    is ($imp->signature, 0, "Signature is 0");
    is ($imp->computed_signature, 8, "Signature computed ok (8)");
    is ($imp->total_output_pages, 8, "Max page ok (8)");
}

{
    my $pdffile = create_pdf("1x1-8", 1..8);
    my $imp = PDF::Imposition->new(file => $pdffile, cover => 1,
                                   pages_per_sheet => 4,
                                   schema => '1x1',
                                  );
    $imp->impose;
    test_is_deeply($imp,
                   [ [1], [2], [3], [4], [5], [6], [7], [8] ],
                   "Imposing 8 pages OK", 8);
    is ($imp->signature, 0, "Signature is 0");
    is ($imp->computed_signature, 8, "Signature computed ok (8)");
    is ($imp->total_output_pages, 8, "Max page ok (8)");
}

{
    my $pdffile = create_pdf("1x1-10-8pps", 1..10);
    my $imp = PDF::Imposition->new(file => $pdffile,
                                   cover => 1,
                                   schema => '1x1',
                                   pages_per_sheet => 8,
                                  );
    $imp->impose;
    test_is_deeply($imp,
                   [ [1], [2], [3], [4], [5], [6], [7], [8],
                     [9], [], [],   [],  [],  [],  [], [10],
                   ],
                   "Imposing 10 pages OK", 10);
    is ($imp->signature, 0, "Signature is 0");
    is ($imp->computed_signature, 16, "Signature computed ok (16)");
    is ($imp->total_output_pages, 16, "Max page ok (8)");
}

{
    my $pdffile = create_pdf("1x1-10", 1..10);
    my $imp = PDF::Imposition->new(file => $pdffile,
                                   cover => 1,
                                   schema => '1x1',
                                   pages_per_sheet => 4,
                                  );
    $imp->impose;
    test_is_deeply($imp,
                   [ [1], [2], [3], [4], [5], [6], [7], [8],
                     [9], [], [],   [10],
                   ],
                   "Imposing 10 pages OK", 10);
    is ($imp->signature, 0, "Signature is 0");
    is ($imp->computed_signature, 12, "Signature computed ok (12)");
    is ($imp->total_output_pages, 12, "Max page ok (12)");
}



my $pdffile = create_pdf("2up-4", 1..4);
diag "using $pdffile";

my $imp = PDF::Imposition->new(file => $pdffile);
$imp->impose;

test_is_deeply($imp,
          [
           [ 4, 1 ],
           [ 2, 3 ]
          ],
          "Simple imposition ok", 4);

$pdffile = create_pdf("2up-20", 1..20);
$imp = PDF::Imposition->new(file => $pdffile);
$imp->impose;
test_is_deeply($imp,
          [
           [ 20, 1 ],
           [ 2, 19 ],
           [ 18, 3 ],
           [ 4, 17 ],
           [ 16, 5 ],
           [ 6, 15 ],
           [ 14, 7 ],
           [ 8, 13 ],
           [ 12, 9 ],
           [ 10, 11]
          ],
          "Imposing 20 pages OK", 20);

$pdffile = create_pdf("2up-s4", 1..16);
$imp = PDF::Imposition->new(file => $pdffile);
$imp->signature(4);
$imp->impose;
test_is_deeply($imp,
          [
           [4,  1],
           [2 , 3],
           [8 , 5],
           [6,  7],
           [12, 9],
           [10, 11],
           [16, 13],
           [14, 15]
          ],
          "Signatures appear to work", 16);

########################################################################
#                                                                      #
# We can't determine without a visual inspection if the page is placed #
# on the right side, (when one page is empty, but we suppose so :-)    #
#                                                                      #
########################################################################

$pdffile = create_pdf("2up-p19", 1..19);
$imp = PDF::Imposition->new(file => $pdffile);
$imp->impose;
test_is_deeply($imp,
          [
           [ 1,  ],
           [ 2, 19 ],
           [ 18, 3 ],
           [ 4, 17 ],
           [ 16, 5 ],
           [ 6, 15 ],
           [ 14, 7 ],
           [ 8, 13 ],
           [ 12, 9 ],
           [ 10, 11]
          ],
          "Imposing 19 pages OK", 19);

$pdffile = create_pdf("2up-p19-cover", 1..19);
$imp = PDF::Imposition->new(file => $pdffile);
$imp->cover(1);
$imp->impose;
test_is_deeply($imp,
          [
           [ 19, 1 ],
           [ 2,  ],
           [ 18, 3 ],
           [ 4, 17 ],
           [ 16, 5 ],
           [ 6, 15 ],
           [ 14, 7 ],
           [ 8, 13 ],
           [ 12, 9 ],
           [ 10, 11]
          ],
          "Imposing 19 pages OK", 19);

$pdffile = create_pdf("2up-18", 1..18);
$imp = PDF::Imposition->new(file => $pdffile);
$imp->impose;
test_is_deeply($imp,
          [
           [ 1,  ],
           [ 2,  ],
           [ 18, 3 ],
           [ 4, 17 ],
           [ 16, 5 ],
           [ 6, 15 ],
           [ 14, 7 ],
           [ 8, 13 ],
           [ 12, 9 ],
           [ 10, 11]
          ],
          "Imposing 18 pages OK", 18);

$pdffile = create_pdf("2up-18-cover", 1..18);
$imp = PDF::Imposition->new(file => $pdffile);
$imp->cover(1);
$imp->impose;
test_is_deeply($imp,
          [
           [ 18, 1 ],
           [ 2,  ],
           [ 3,  ],
           [ 4, 17 ],
           [ 16, 5 ],
           [ 6, 15 ],
           [ 14, 7 ],
           [ 8, 13 ],
           [ 12, 9 ],
           [ 10, 11]
          ],
          "Imposing 18 pages OK", 18);


$pdffile = create_pdf("2up-17", 1..17);
$imp = PDF::Imposition->new(file => $pdffile);
$imp->impose;
test_is_deeply($imp,
          [
           [ 1,  ],
           [ 2,  ],
           [ 3,  ],
           [ 4, 17 ],
           [ 16, 5 ],
           [ 6, 15 ],
           [ 14, 7 ],
           [ 8, 13 ],
           [ 12, 9 ],
           [ 10, 11]
          ],
          "Imposing 17 pages OK", 17);

$pdffile = create_pdf("2up-17-cover", 1..17);
$imp = PDF::Imposition->new(file => $pdffile);
$imp->cover(1);
$imp->impose;
test_is_deeply($imp,
          [
           [ 17, 1 ],
           [ 2,  ],
           [ 3,  ],
           [ 4,  ],
           [ 16, 5 ],
           [ 6, 15 ],
           [ 14, 7 ],
           [ 8, 13 ],
           [ 12, 9 ],
           [ 10, 11]
          ],
          "Imposing 18 pages OK", 17);

$pdffile = create_pdf("2down", 1..17);
$imp = PDF::Imposition->new(
                            file => $pdffile,
                            schema => '2down',
                           );

$imp->impose;

# here the odd pages are on the left and the even on the right. This
# is basically an artefact of the text extraction, and of the rotation
# of the page, I guess. There is no way we can check this blindly.

test_is_deeply($imp,
          [
           [ 1,  ],
           [ 2,  ],
           [ 3,  ],
           [ 17, 4 ],
           [ 5, 16 ],
           [ 15, 6 ],
           [ 7, 14 ],
           [ 13, 8 ],
           [ 9, 12 ],
           [ 11, 10]
          ],
          "Imposing 17 pages OK", 17);

$pdffile = create_pdf("2down-17-cover", 1..17);
$imp = PDF::Imposition->new(
                            file => $pdffile,
                            schema => '2down',
                            cover => 1,
                           );

$imp->impose;
test_is_deeply($imp,
          [
           [ 1 ,17 ],
           [ 2,  ],
           [ 3,  ],
           [ 4,  ],
           [ 5, 16 ],
           [ 15, 6 ],
           [ 7, 14 ],
           [ 13, 8 ],
           [ 9, 12 ],
           [ 11, 10]
          ],
          "Imposing 17 pages OK", 17);

# print Dumper($imp->page_sequence_for_booklet);

$pdffile = create_pdf("2x4x2", 1..32);
$imp = PDF::Imposition->new(
                            file => $pdffile,
                            schema => '2x4x2',
                           );
$imp->impose;

test_is_deeply($imp,
          [
           [ '9', '8',
             '16', '1' ],
           [ '7', '10',
             '2', '15' ],

           [ '11', '6',
             '14', '3' ],
           [ '5', '12',
             '4', '13' ],

           [ '25', '24',
             '32', '17' ],
           [ '23', '26',
             '18', '31' ],

           [ '27', '22',
             '30', '19' ],
           [ '21', '28',
             '20', '29' ],

          ], "2x4x2 appears to work", 32);

$pdffile = create_pdf("2side", 1..7);
$imp = PDF::Imposition->new(
                            file => $pdffile,
                            schema => '2side',
                           );
$imp->impose;
test_is_deeply($imp,
               [
                [ 1, 2], [3,4], [5,6], [7]
               ],
               "2 side works", 7);

$pdffile = create_pdf("1x4x2cutfoldbind", 1..8);
$imp = PDF::Imposition->new(
                            file => $pdffile,
                            schema => '1x4x2cutfoldbind',
                           );

$imp->impose;
test_is_deeply($imp,
               [
                [ 4, 1, 8, 5 ],
                [ 2, 3, 6, 7 ],
               ],
               "1x4x2cutfoldbind works", 8);


$pdffile = create_pdf("1x4x2cutfoldbind", 1..20);
$imp = PDF::Imposition->new(
                            file => $pdffile,
                            schema => '1x4x2cutfoldbind',
                           );

$imp->impose;
test_is_deeply($imp,
               [
                [ 4, 1, 8, 5 ],
                [ 2, 3, 6, 7 ],
                [ 12, 9, 16, 13 ],
                [ 10, 11, 14, 15 ],
                [ 20, 17],
                [ 18, 19],
               ],
               "1x4x2cutfoldbind works", 20);

$pdffile = create_pdf("1x4x2cutfoldbind-even", 1..20);
$imp = PDF::Imposition->new(
                            file => $pdffile,
                            cover => 1,
                            schema => '1x4x2cutfoldbind',
                           );

$imp->impose;
test_is_deeply($imp,
               [
                [ 4, 1, 8, 5 ],
                [ 2, 3, 6, 7 ],
                [ 12, 9, 16, 13 ],
                [ 10, 11, 14, 15 ],
                [ 20, 17],
                [ 18, 19],
               ],
               "1x4x2cutfoldbind works", 20);



$pdffile = create_pdf("1x4x2cutfoldbind-odd", 1..3);
$imp = PDF::Imposition->new(
                            file => $pdffile,
                            cover => 1,
                            schema => '1x4x2cutfoldbind',
                           );

$imp->impose;
test_is_deeply($imp,
               [
                [  3, 1 ],
                [ 2,  ],
               ],
               "1x4x2cutfoldbind works, 3 is where 8 should be", 3);

$pdffile = create_pdf("1x4x2cutfoldbind-odd-2", 1..6);
$imp = PDF::Imposition->new(
                            file => $pdffile,
                            cover => 1,
                            schema => '1x4x2cutfoldbind',
                           );

$imp->impose;
test_is_deeply($imp,
               [
                [ 4, 1, 6 ,5   ],
                [ 2, 3 ],
               ],
               "1x4x2cutfoldbind works, 6 is where 8 should be", 6);

$pdffile = create_pdf("1x4x2cutfoldbind-odd-3", 1..7);
$imp = PDF::Imposition->new(
                            file => $pdffile,
                            cover => 1,
                            schema => '1x4x2cutfoldbind',
                           );

$imp->impose;
test_is_deeply($imp,
               [
                [ 4, 1, 7 ,5   ],
                [ 2, 6, 3 ], # messed up by the extraction
               ],
               "1x4x2cutfoldbind works, 7 is where 8 should be", 7);

$pdffile = create_pdf("4up", 1..48);

$imp = PDF::Imposition->new(file => $pdffile,
                            schema => '4up');

$imp->impose;
test_is_deeply($imp,
               [
                [ 48,  1, 36, 13 ],
                [ 2,  47, 14, 35 ],
                [ 46,  3, 34, 15 ],
                [ 4,  45, 16, 33 ],
                [ 44,  5, 32, 17 ],
                [ 6,  43, 18, 31 ],
                [ 42,  7, 30, 19 ],
                [ 8,  41, 20, 29 ],
                [ 40,  9, 28, 21 ],
                [ 10, 39, 22, 27 ],
                [ 38, 11, 26, 23 ],
                [ 12, 37, 24, 25 ],
               ],
               "4up looks ok", 48);

$pdffile = create_pdf("4up-short", 1..8);
$imp = PDF::Imposition->new(file => $pdffile,
                            schema => '4up');

$imp->impose;
test_is_deeply($imp,
               [
                [ 8, 1, 6, 3],
                [ 2, 7, 4, 5],
               ],
               "4up with 8 pages looks ok", 8);

$pdffile = create_pdf("4up-very-short", 1..3);
$imp = PDF::Imposition->new(file => $pdffile,
                            cover => 1,
                            signature => 8,
                            schema => '4up');
$imp->impose;
test_is_deeply($imp,
               [
                [ 3, 1, ],
                [ 2, ],
               ],
               "4up with 3 pages looks ok", 3);


$pdffile = create_pdf("4up-very-short-nosig", 1..3);
$imp = PDF::Imposition->new(file => $pdffile,
                            cover => 1,
                            schema => '4up');
$imp->impose;
test_is_deeply($imp,
               [
                [ 3, 1, ],
                [ 2, ],
               ],
               "4up with 3 pages looks ok", 3);

$pdffile = create_pdf("repeat2side", 1..3);
$imp = PDF::Imposition->new(file => $pdffile, schema => '1repeat2side');
$imp->impose;
test_is_deeply($imp, [ [ 1, 1 ], [ 2, 2 ], [ 3, 3 ] ], "1repeat2side ok", 3);


$pdffile = create_pdf("repeat2top", 1..3);
$imp = PDF::Imposition->new(file => $pdffile, schema => '1repeat2top');
$imp->impose;
test_is_deeply($imp, [ [ 1, 1 ], [ 2, 2 ], [ 3, 3 ] ], "1repeat2top ok", 3);

$pdffile = create_pdf("repeat4", 1..3);
$imp = PDF::Imposition->new(file => $pdffile, schema => '1repeat4');
$imp->impose;
test_is_deeply($imp, [ [ 1, 1, 1, 1 ], [ 2, 2, 2, 2 ], [ 3, 3, 3, 3 ] ],
               "1repeat4 ok", 3);

$pdffile = create_pdf("ea4x4", 1..16);
$imp = PDF::Imposition->new(file => $pdffile, schema => 'ea4x4');
$imp->impose;
test_is_deeply($imp, [ [ 13, 4, 16, 1 ], [ 3, 14, 2, 15 ],
                       [ 9, 8, 12, 5],   [ 7, 10, 6, 11 ] ],
               "ea4x4", 16);


$pdffile = create_pdf("ea4x4-odd", 1..17);
$imp = PDF::Imposition->new(file => $pdffile, schema => 'ea4x4');
$imp->impose;
test_is_deeply($imp, [ [ 13, 4, 16, 1 ], [ 3, 14, 2, 15 ],
                       [ 9, 8, 12, 5],   [ 7, 10, 6, 11 ], [ 17 ], ],
               "ea4x4-odd", 17);


$pdffile = create_pdf("1x8x2", 1..16);

$imp = PDF::Imposition->new(file => $pdffile, schema => '1x8x2');
$imp->impose;

test_is_deeply($imp, [
                      [ 5, 12, 9, 8,
                        4, 13, 16, 1 ],
                      [ 7, 10, 11, 6,
                        2, 15, 14, 3 ],
                     ], "1x8x2", 16);


$pdffile = create_pdf("2x4x1", 1..18);

$imp = PDF::Imposition->new(file => $pdffile, schema => '2x4x1');
$imp->impose;

test_is_deeply($imp, [
                      [ 5, 4, 8, 1 ],
                      [ 3, 6, 2, 7 ],
                      [ 13, 12, 16, 9 ],
                      [ 11, 14, 10, 15 ],
                      [ 17 ],
                      [ 18 ],
                     ], "2x4x1", 18);


$pdffile = create_pdf("duplex2up", 1..8);

$imp = PDF::Imposition->new(file => $pdffile, schema => 'duplex2up');
$imp->impose;

test_is_deeply($imp, [
                      [ 8, 1 ],
                      [ 2, 7 ],
                      [ 6, 3 ],
                      [ 4, 5 ],
                     ], "duplex2up", 8);




sub create_pdf {
    my ($filename, @pages) = @_;
    unless ($filename =~ m/\.pdf$/) {
        $filename .= ".pdf";
    }
    $filename = catfile($testdir, $filename);
    # print "Using $testdir";
    my $pdf = PDF::API2->new();
    # common settings
    $pdf->mediabox(80, 120);
    my $font = $pdf->corefont('Helvetica-Bold');
    for my $p (@pages) {
        my $page = $pdf->page();
        my $text = $page->text();
        $text->font($font, 20);
        $text->translate(40, 60);
        $text->text_center("Pg $p");
        my $line = $page->gfx;
        $line->linewidth(1);
        $line->strokecolor('black');
        $line->rectxy(1, 1, 79, 119);
        $line->stroke;
    }
    $pdf->saveas($filename);
    return $filename;
}

sub extract_pdf {
    my $pdf = shift;
    save_output($pdf);
    my $txt = $pdf;
    $txt =~ s/\.pdf$/.txt/;
    system(pdftotext => $pdf) == 0 or die 'pdftotext failed $?';
    local $/ = undef;
    open (my $fh, '<', $txt) or die "cannot open $txt $!";
    my $ex = <$fh>;
    close $fh;
    return extract_pages($ex);
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

        while ($p =~ m/\s*(Pg (\d+))\s*/gs) {
            push @nums, $2;
        }
        push @out, \@nums;
    }
    return \@out;
}

sub save_output {
    my $pdf = shift;
    diag "PDF " . basename($pdf) . " left in " . catfile($outputdir,
                                                         basename($pdf));
    copy($pdf, $outputdir)
      or die "Cannot move $pdf in $outputdir $!";
}

sub test_is_deeply {
    my ($imposer, $seq, $message, $pages) = @_;
    ok($imposer->outfile, "output is here");
    ok((-f $imposer->outfile), "File created");
  SKIP:
    {
        skip "No pdftotext available", 2 if $skipex;
        my $extracted = extract_pdf($imposer->outfile);
        is_deeply($extracted, $seq, $message)
          or diag "Extracted: " . Dumper($extracted) . " expected " . Dumper($seq);
        all_pages_present($imposer->outfile, $pages);
    }
    unlink $imposer->outfile or die "Cannot unlink outfile $!";
}

sub all_pages_present {
    my ($pdf, $pages) = @_;
    my @array = @{ extract_pdf($pdf) };
    my @expected = (1 .. $pages);
    my @result;
    foreach my $physical (@array) {
        push @result, @$physical;
    }

    @result = sort { $a <=> $b } @result;
    my @filtered;
    my %dups;
    while (@result) {
        my $p = shift @result;
        if (!$dups{$p}) {
            push @filtered, $p;
            $dups{$p} = 1;
        }
    }
    is_deeply \@filtered, \@expected, "All pages present in $pdf";
}

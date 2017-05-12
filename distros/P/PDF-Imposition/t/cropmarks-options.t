#!perl

use strict;
use warnings;
use Test::More tests => 18;
use PDF::Imposition;
use File::Spec::Functions;
use File::Temp;
use File::Path qw/remove_tree make_path/;
use Data::Dumper;

my $outputdir = catdir("t", "output", $PDF::Imposition::VERSION . '-cropmarks-options');
if (-d $outputdir) {
    remove_tree($outputdir);
}
make_path($outputdir);

my $pdf = catfile(qw/t pdfv16.pdf/);

my @bad = (
           { paper_thickness => 'asdfas' },
           { font_size => 'asdfa' },
           { cropmark_offset => 'asdef' },
           { cropmark_length => 'asdf' },
          );
my @good = (
            {},
            { paper_thickness => '3mm' },
            {
             paper_thickness => '3mm',
             font_size => '24pt',
            },
            {
             paper_thickness => '3mm',
             font_size => '24pt',
             cropmark_length => '30mm',
            },
            {
             paper_thickness => '3mm',
             font_size => '24pt',
             cropmark_length => '30mm',
             cropmark_offset => '0.1mm',
            }
           );

my $count = 0;
foreach my $fail (@bad) {
    my $out = catfile($outputdir, ++$count . '.pdf');
    diag "Imposing $out with " . Dumper($fail);
    my $imposer = PDF::Imposition->new(schema => '2up',
                                       file => $pdf,
                                       outfile => $out,
                                       cover => 1,
                                       paper => 'A3',
                                       %$fail);
    eval { $imposer->impose };
    ok ($@, "Imposer failed with $@");
    ok (!-f $out, "$out not created");
}
foreach my $opts (@good) {
    my $out = catfile($outputdir, ++$count . '.pdf');
    diag "Imposing $out with " . Dumper($opts);
    my $imposer = PDF::Imposition->new(schema => '2up',
                                       file => $pdf,
                                       outfile => $out,
                                       cover => 1,
                                       paper => 'A3',
                                       %$opts);
    eval { $imposer->impose };
    ok (!$@, "Imposing seems ok") or diag $@;
    ok (-f $out, "$out created");
}

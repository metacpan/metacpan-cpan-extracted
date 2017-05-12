#!perl

use strict;
use warnings;

use Test::More;
use PDF::Imposition;
use File::Spec::Functions;

eval "use Test::Memory::Cycle";

my @schemas = PDF::Imposition->available_schemas;

if ($ENV{RELEASE_TESTING} && !$@) {
    plan tests => @schemas * 4 * 2;
}
else {
    plan skip_all => "No release testing, skipping";
}

my $outdir = catdir(t => output => $PDF::Imposition::VERSION . '-cycles');
unless (-d $outdir) {
    mkdir catdir("t", "output") unless -d catdir("t", "output");
    mkdir $outdir or die "Cannot create $outdir $!";
}


foreach my $schema (@schemas) {
    foreach my $testfile (qw/pdfv16.pdf sample2e.pdf/) {
        foreach my $paper ('', 'a3') {
            diag "Testing $schema against $testfile with paper $paper";
            my $pdf = catfile(t => $testfile);
            my $outfile = catfile($outdir, join('-', 'cycle',
                                                ($paper ? $paper : 'nocropmarks'),
                                                $schema, $testfile));

            if (-f $outfile) {
                unlink $outfile or die $!;
            }

            my $imposer = PDF::Imposition->new(
                                               file => $pdf,
                                               schema => $schema,
                                               signature => '40-80',
                                               cover => 1,
                                               outfile => $outfile,
                                               paper => $paper,
                                              );
            $imposer->impose;
            memory_cycle_ok($imposer, "No memory cycles found for $schema $testfile");
            ok(-f $outfile, "Produced $outfile");
        }
    }
}


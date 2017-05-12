#!perl
use strict;
use warnings;
use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More skip_all => 'Test with LeakTrace is disabled';

use Test::LeakTrace;
use PDF::Imposition;
use File::Spec::Functions;

my @schemas = PDF::Imposition->available_schemas;

foreach my $schema (@schemas) {
    foreach my $testfile (qw/pdfv16.pdf sample2e.pdf/) {
        my $pdf = catfile(t => $testfile);
        my $outfile = catfile(t => output => join('-', 'leaks',
                                                  $schema, $testfile));
        if (-f $outfile) {
            unlink $outfile or die $!;
        };
        no_leaks_ok {
            my $imposer = PDF::Imposition->new(
                                               file => $pdf,
                                               schema => $schema,
                                               signature => '40-80',
                                               cover => 1,
                                               outfile => $outfile
                                              );
            $imposer->impose;
        } "No leaks found for $testfile $schema";
        ok (-f $outfile, "Generated $outfile");
    }
}


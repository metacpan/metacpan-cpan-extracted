use strict;
use warnings;
use Test::More;

use PDL::Graphics::Gnuplot qw(gpwin);
use File::Temp qw(tempfile);
use PDL;

# Testing 'pdfcairo' terminal separately because Gnuplot only writes the PDF
# when plotting is done.

if( $PDL::Graphics::Gnuplot::valid_terms->{pdfcairo} ) {
    plan tests => 1;
} else {
    plan skip_all => 'No terminal pdfcairo';
}

my (undef, $testoutput) = tempfile('pdl_graphics_gnuplot_test_pdfcairo_XXXXXXX',
    SUFFIX => '.pdf');

my $x = zeroes(50)->xlinvals(0, 7);
my $w = gpwin("pdfcairo", output => $testoutput);
$w->plot(with => 'lines', $x, $x->sin);
$w->close;
ok -s $testoutput, 'File has size';

unlink($testoutput) or warn "\$!: $!";

done_testing;

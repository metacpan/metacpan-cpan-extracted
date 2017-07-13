use Test::More (tests => 1);

use PDF::Builder;

my $pdf = PDF::Builder->open('t/resources/sample.pdf');

ok($pdf->stringify(),
   q{open() followed by saveas() doesn't crash});

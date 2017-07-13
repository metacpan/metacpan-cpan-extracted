use Test::More;
use Test::Exception;

use strict;
use warnings;

use PDF::Builder;

my $pdf = PDF::Builder->new();

foreach my $font (qw(bankgothic courier courierbold courierboldoblique
                     courieroblique georgia georgiabold georgiabolditalic
                     georgiaitalic helvetica helveticabold helveticaboldoblique
                     helveticaoblique symbol timesbold timesbolditalic
                     timesitalic timesroman trebuchet trebuchetbold
                     trebuchetbolditalic trebuchetitalic verdana verdanabold
                     verdanabolditalic verdanaitalic webdings wingdings
                     zapfdingbats)) {
    lives_ok(sub { $pdf->corefont($font) }, "Load font $font");
}

done_testing();

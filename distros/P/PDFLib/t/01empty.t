use Test;
BEGIN { plan tests => 3 }

use PDFLib;
ok(1);

my $pdf = PDFLib->new();
ok($pdf);

$pdf->start_page();
ok($pdf->get_buffer);


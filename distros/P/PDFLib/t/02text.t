use Test;
BEGIN { plan tests => 3 }

use PDFLib;
ok(1);

my $pdf = PDFLib->new();

$pdf->start_page();
ok(!$pdf->print("Hello World"));

ok($pdf->get_buffer);


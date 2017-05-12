use Test;
BEGIN { plan tests => 4 }

use PDFLib;
ok(1);

my $pdf = PDFLib->new();
ok($pdf);

my $img = $pdf->load_image(
        pdf => $pdf,
        filename => "img/axkit.png",
        filetype => "png",
        );

ok($img);

$pdf->start_page();

$pdf->add_image(img => $img, x => 40, y => 40);

ok($pdf->get_buffer);


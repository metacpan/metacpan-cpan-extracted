use Test;
BEGIN { plan tests => 4 }
use PDFLib;

my $pdf;
$pdf = PDFLib->new(filename => "test.pdf");

ok($pdf);

$pdf->start_page;

$pdf->save_graphics_state;

my $bb = $pdf->new_bounding_box(
	x => 1, y => 800, w => 593, h => 50, align => "center",
);

$bb->set_font(face => "Times", bold => 1, size => 24);

$bb->print("Bounding Box Demonstration");

$bb->finish;

$pdf->restore_graphics_state;

$bb = $pdf->new_bounding_box(
    x => 30, y => 750, w => 250, h => 200
);

$bb->set_value(leading => $bb->get_value("fontsize") + 2);

$bb->print(<<'EOT');
This module is a port and enhancement of the AxKit presentation tool,
B<AxPoint>. It takes an XML description of a slideshow, and generates
a PDF. The resulting presentations are very nice to look at, possibly
rivalling PowerPoint, and almost certainly better than most other
freeware presentation tools on Unix/Linux.

EOT

$bb->print_line("");
$bb->print_line("");

$bb->set_font(face => "Times", italic => 1);
$bb->set_value(leading => $bb->get_value("fontsize") + 2);

$bb->print(<<'EOT');
The presentations support slide transitions, PDF bookmarks, bullet
points, source code (fixed font) sections, images, colours, bold and
italics, hyperlinks, and transition effects for all the bullet
points, source, and image sections.

EOT

$bb->print_line("");
$bb->print_line("");

$bb->set_color(rgb => [1,0,1]);

my $leftover = $bb->print(<<'EOT');
Rather than describing the format in detail, it is far easier to
examine (and copy) the example in the testfiles directory in the
distribution. We have included that verbatim here in case you lost it
during the install
EOT

ok($leftover);

$bb->finish;

$bb = $pdf->new_bounding_box(
    x => 300, y => 750, w => 250, h => 200
);

$bb->print($leftover);

$bb->finish;

# one liner
$bb = $pdf->new_bounding_box(
	x => 400, y => 500, w => 200, h => 40
);

$bb->print("small box");

$bb->finish;

$bb = $pdf->new_bounding_box(
	x => 20, y => 270, h => 255, w => 421, wrap => 0,
); # bug in 1.18, reported by Aaron
$bb->print("Hello\nworld");
$bb->finish;

$pdf->finish;

undef $pdf;

ok(-e "test.pdf");
ok(-M _ <= 0);


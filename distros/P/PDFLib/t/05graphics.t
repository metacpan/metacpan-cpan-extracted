use Test;
BEGIN { plan tests => 5 }
use PDFLib;

# my $pdf = PDFLib->new(filename => "/tmp/test.pdf");
my $pdf = PDFLib->new(filename => "test.pdf");

ok($pdf);

$pdf->start_page;

ok(!$pdf->set_line_width(0.1));
ok(!$pdf->set_dash(1, 2));

my @a4 = @{$PDFLib::Page::Size{a4}};

for (my $i = 0; $i < $a4[0]; $i += 10) {
    $pdf->save_graphics_state;
    unless ($i % 100) {
        $pdf->set_line_width(1.0);
    }
    unless ($i % 50) {
        $pdf->set_dash(0, 0);
    }
    $pdf->move_to($i, 0);
    $pdf->line_to($i, $a4[1]);
    $pdf->stroke;
    $pdf->restore_graphics_state;
}

for (my $i = 0; $i < $a4[1]; $i += 10) {
    $pdf->save_graphics_state;
    unless ($i % 50) {
        $pdf->set_dash(0,0);
    }
    unless ($i % 100) {
        $pdf->set_line_width(1.0);
    }
    $pdf->move_to(0, $i);
    $pdf->line_to($a4[0], $i);
    $pdf->stroke;
    $pdf->restore_graphics_state;
}

use constant FONTSIZE => 10.0;
use constant DELTA => 9;
use constant RADIUS => 12.0;

$pdf->set_font(
    face => "Helvetica", bold => 1, size => FONTSIZE,
);

for (my $i = 100; $i < $a4[0]; $i += 100) {
    $pdf->save_graphics_state;
    $pdf->set_colour(type => "fill", gray => 0.8);
    $pdf->circle(x => $i, y => 20, r => RADIUS);
    $pdf->fill;
    $pdf->restore_graphics_state;
    $pdf->print_at($i, x => $i - DELTA, y => 20 - FONTSIZE/3);
}

for (my $i = 100; $i < $a4[1]; $i += 100) {
    $pdf->save_graphics_state;
    $pdf->set_color(type => "fill", gray => 0.8);
    $pdf->circle(x => 40, y => $i, r => RADIUS);
    $pdf->fill;
    $pdf->restore_graphics_state;
    $pdf->print_at($i, x => 40 - DELTA, y => $i - FONTSIZE/3);
}

$pdf->set_dash(0, 0);
$pdf->move_to(30, 75);
$pdf->bezier(
    x1 => 240, y1 => 30,
    x2 => 240, y2 => 30,
    x3 => 300, y3 => 120,
);
$pdf->stroke;

$pdf->finish;
undef $pdf;

ok(-e "test.pdf");
ok(-M _ <= 0);



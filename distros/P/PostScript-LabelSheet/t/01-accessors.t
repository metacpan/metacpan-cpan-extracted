#!perl -T

use Test::More tests => 14;
use PostScript::LabelSheet;

my $sheet = new PostScript::LabelSheet({width => 147});
isa_ok($sheet, 'PostScript::LabelSheet');
is($sheet->width(), 147);

my $r = $sheet->width(42);
is($r, $sheet);
is($sheet->width(), 42);

$sheet
    ->margin(10)
    ->spacing(20)
    ;
is($sheet->v_margin(), 10);
is($sheet->h_margin(), 10);
is($sheet->v_spacing(), 20);
is($sheet->h_spacing(), 20);

$sheet
    ->width(595)
    ->height(842)
    ->margin(28.34)
    ->columns(4)
    ->rows(10)
    ->spacing(14.17);
is($sheet->label_width(), 123.9525);
is($sheet->label_height(), 65.779);
is($sheet->width(),
    $sheet->columns() * $sheet->label_width() + ($sheet->columns() - 1) * $sheet->h_spacing() + 2 * $sheet->h_margin()
);
is($sheet->height(),
    $sheet->rows() * $sheet->label_height() + ($sheet->rows() - 1) * $sheet->v_spacing() + 2 * $sheet->v_margin()
);

$sheet
    ->label_width(120)
    ->label_height(100)
;
is($sheet->columns(), 4);
is($sheet->rows(), 7);

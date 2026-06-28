#!/usr/bin/env perl
use strict;
use warnings;
use PDF::Make::Document;
use PDF::Make::Page qw(:fonts);
use PDF::Make::Canvas;

my $doc = PDF::Make::Document->new;
$doc->title('PDF::Make Styled Demo');
$doc->author('PDF::Make');
$doc->creator('PDF::Make');

# Letter size: 612 x 792 points
my $page = $doc->add_page(612, 792);

# Register fonts
$page->add_std14_font('F1',  HELVETICA);
$page->add_std14_font('F1B', HELVETICA_BOLD);
$page->add_std14_font('F1O', HELVETICA_OBLIQUE);
$page->add_std14_font('F2',  TIMES_ROMAN);
$page->add_std14_font('F2B', TIMES_BOLD);
$page->add_std14_font('F2I', TIMES_ITALIC);
$page->add_std14_font('F3',  COURIER);
$page->add_std14_font('F3B', COURIER_BOLD);

my $c = PDF::Make::Canvas->new;
my $W = 612;
my $H = 792;
my $margin = 54;  # 0.75 inch

# Helper: absolute text placement (Tm sets an absolute text matrix)
sub text_at {
    my ($canvas, $font, $size, $x, $y, $text) = @_;
    $canvas->BT
           ->Tf($font, $size)
           ->Tm(1, 0, 0, 1, $x, $y)
           ->Tj($text)
           ->ET;
}

# ── Header bar ──────────────────────────────────────────────
$c->q
   ->rg(0.13, 0.15, 0.20)
   ->re(0, $H - 80, $W, 80)->f
   ->Q;

$c->BT
   ->rg(1, 1, 1)
   ->Tf('F1B', 26)->Tm(1, 0, 0, 1, $margin, $H - 50)
   ->Tj('PDF::Make')
   ->rg(0.55, 0.75, 0.95)
   ->Tf('F1', 12)->Tm(1, 0, 0, 1, $margin, $H - 68)
   ->Tj('A from-scratch PDF generation library for Perl')
   ->ET;

# Accent line
$c->q->rg(0.20, 0.60, 0.86)->re(0, $H - 83, $W, 3)->f->Q;

# ── Section 1: Typography ──────────────────────────────────
my $y = $H - 112;

$c->BT->rg(0.20, 0.60, 0.86)
   ->Tf('F1B', 14)->Tm(1, 0, 0, 1, $margin, $y)
   ->Tj('Typography')->ET;

$y -= 22;
my @type_samples = (
    ['F1',  11, 'Helvetica - The quick brown fox jumps over the lazy dog.'],
    ['F1B', 11, 'Helvetica Bold - The quick brown fox jumps over the lazy dog.'],
    ['F1O', 11, 'Helvetica Oblique - The quick brown fox jumps over the lazy dog.'],
    ['F2',  11, 'Times Roman - The quick brown fox jumps over the lazy dog.'],
    ['F2B', 11, 'Times Bold - The quick brown fox jumps over the lazy dog.'],
    ['F2I', 11, 'Times Italic - The quick brown fox jumps over the lazy dog.'],
    ['F3',  9.5, 'Courier - The quick brown fox jumps over the lazy dog.'],
    ['F3B', 9.5, 'Courier Bold - The quick brown fox jumps over the lazy dog.'],
);

$c->BT->rg(0.15, 0.15, 0.15);
for my $s (@type_samples) {
    $c->Tf($s->[0], $s->[1])
      ->Tm(1, 0, 0, 1, $margin, $y)
      ->Tj($s->[2]);
    $y -= 16;
}
$c->ET;

# ── Section 2: Color Palette ───────────────────────────────
$y -= 12;
$c->BT->rg(0.20, 0.60, 0.86)
   ->Tf('F1B', 14)->Tm(1, 0, 0, 1, $margin, $y)
   ->Tj('Color Palette')->ET;

$y -= 20;
my @colors = (
    [0.20, 0.60, 0.86, 'Primary Blue'],
    [0.16, 0.50, 0.73, 'Dark Blue'],
    [0.18, 0.80, 0.44, 'Emerald'],
    [0.91, 0.30, 0.24, 'Alizarin'],
    [0.95, 0.61, 0.07, 'Orange'],
    [0.56, 0.27, 0.68, 'Amethyst'],
    [0.13, 0.15, 0.20, 'Charcoal'],
    [0.58, 0.65, 0.65, 'Concrete'],
);

my $swatch_x = $margin;
my $swatch_w = 56;
my $swatch_h = 32;
my $gap = 6;

for my $col (@colors) {
    my ($r, $g, $b, $name) = @$col;
    $c->q->rg($r, $g, $b)
       ->re($swatch_x, $y - $swatch_h, $swatch_w, $swatch_h)->f->Q;
    text_at($c, 'F1', 6, $swatch_x + 2, $y - $swatch_h - 9, $name);
    $swatch_x += $swatch_w + $gap;
}

# ── Section 3: Shapes & Paths ─────────────────────────────
$y -= $swatch_h + 26;
$c->BT->rg(0.20, 0.60, 0.86)
   ->Tf('F1B', 14)->Tm(1, 0, 0, 1, $margin, $y)
   ->Tj('Shapes & Paths')->ET;

$y -= 18;
my $shape_w = 90;
my $shape_h = 60;
my $shape_gap = 30;

# Stroked rectangle
my $sx = $margin;
$c->q->w(2)->RG(0.20, 0.60, 0.86)
   ->re($sx, $y - $shape_h, $shape_w, $shape_h)->S->Q;
text_at($c, 'F1', 7, $sx + 28, $y - $shape_h - 12, 'Stroke');

# Filled rectangle
$sx += $shape_w + $shape_gap;
$c->q->rg(0.18, 0.80, 0.44)
   ->re($sx, $y - $shape_h, $shape_w, $shape_h)->f->Q;
text_at($c, 'F1', 7, $sx + 33, $y - $shape_h - 12, 'Fill');

# Fill + stroke rectangle
$sx += $shape_w + $shape_gap;
$c->q->w(2)->RG(0.56, 0.27, 0.68)->g(0.93)
   ->re($sx, $y - $shape_h, $shape_w, $shape_h)->B->Q;
text_at($c, 'F1', 7, $sx + 16, $y - $shape_h - 12, 'Fill+Stroke');

# Triangle
$sx += $shape_w + $shape_gap;
my $ty = $y - $shape_h;
$c->q->w(2)->RG(0.91, 0.30, 0.24)->rg(0.95, 0.85, 0.83)
   ->m($sx, $ty)->l($sx + $shape_w, $ty)->l($sx + $shape_w/2, $ty + $shape_h)
   ->h->B->Q;
text_at($c, 'F1', 7, $sx + 24, $ty - 12, 'Triangle');

# ── Section 4: Line Styles ────────────────────────────────
$y -= $shape_h + 30;
$c->BT->rg(0.20, 0.60, 0.86)
   ->Tf('F1B', 14)->Tm(1, 0, 0, 1, $margin, $y)
   ->Tj('Line Styles')->ET;

$y -= 18;
my $lx = $margin;
my $lw = $W - 2 * $margin;

my @lines = (
    [1,   [0.3, 0.3, 0.3],        undef,      0, '1pt solid'],
    [3,   [0.20, 0.60, 0.86],     undef,      0, '3pt solid, blue'],
    [1.5, [0.91, 0.30, 0.24],     [6, 3],     0, '1.5pt dashed, red'],
    [2,   [0.18, 0.80, 0.44],     [0, 6],     1, '2pt dotted, round cap, green'],
    [1,   [0.56, 0.27, 0.68],     [8, 3, 2, 3], 0, '1pt dash-dot, purple'],
);

for my $l (@lines) {
    my ($lwidth, $rgb, $dash, $round_cap, $label) = @$l;
    $c->q->w($lwidth)->RG(@$rgb);
    $c->J(1) if $round_cap;
    $c->d($dash, 0) if $dash;
    $c->m($lx, $y)->l($lx + $lw, $y)->S->Q;
    text_at($c, 'F1', 7, $lx, $y - 10, $label);
    $y -= 22;
}

# ── Section 5: Bezier Curves ──────────────────────────────
$y -= 8;
$c->BT->rg(0.20, 0.60, 0.86)
   ->Tf('F1B', 14)->Tm(1, 0, 0, 1, $margin, $y)
   ->Tj('Bezier Curves')->ET;

$y -= 10;
my $curve_span = $W - 2 * $margin;
$c->q->w(2.5)->RG(0.95, 0.61, 0.07)
   ->m($margin, $y)
   ->c($margin + $curve_span*0.16, $y + 30,
       $margin + $curve_span*0.33, $y - 30,
       $margin + $curve_span*0.5,  $y)
   ->c($margin + $curve_span*0.66, $y + 30,
       $margin + $curve_span*0.83, $y - 30,
       $margin + $curve_span,      $y)
   ->S->Q;

# ── Footer ─────────────────────────────────────────────────
$c->q->rg(0.93, 0.93, 0.93)->re(0, 0, $W, 32)->f->Q;
$c->q->rg(0.20, 0.60, 0.86)->re(0, 32, $W, 2)->f->Q;
text_at($c, 'F1', 7.5, $margin, 12,
    'Generated by PDF::Make - github.com/ThisUsedToBeAnEmail/PDF-Make');

# ── Assemble ───────────────────────────────────────────────
$page->set_content($c->to_bytes);

my $out = 'corpus/styled_demo.pdf';
$doc->to_file($out);
print "Wrote $out\n";

#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

my $tmpfile = tmpnam() . '.pdf';
END { unlink $tmpfile if $tmpfile && -f $tmpfile }

my $b = PDF::Make::Builder->new(file_name => $tmpfile);
$b->add_page(page_size => 'Letter');

# ── Line ─────────────────────────────────────────────────

my $cy = $b->page->cursor_y;
isa_ok($b->add_line(x => 72, ex => 500, fill_colour => '#000'),
    'PDF::Make::Builder', 'add_line solid');
ok($b->page->cursor_y < $cy, 'cursor advances after line');

isa_ok($b->add_line(fill_colour => '#3498db', type => 'dashed'),
    'PDF::Make::Builder', 'add_line dashed');

isa_ok($b->add_line(fill_colour => '#e74c3c', type => 'dots'),
    'PDF::Make::Builder', 'add_line dots');

# ── Box ──────────────────────────────────────────────────

$cy = $b->page->cursor_y;
isa_ok($b->add_box(x => 72, w => 200, h => 50, fill_colour => '#3498db'),
    'PDF::Make::Builder', 'add_box');
ok($b->page->cursor_y < $cy, 'cursor advances after box');

isa_ok($b->add_box(w => 300, h => 30, fill_colour => '#2ecc71'),
    'PDF::Make::Builder', 'add_box default x');

isa_ok($b->add_box(w => 100, h => 20, fill_colour => 'transparent'),
    'PDF::Make::Builder', 'add_box transparent');

# ── Circle ───────────────────────────────────────────────

isa_ok($b->add_circle(fill_colour => '#9b59b6', x => 150, y => 500, r => 40),
    'PDF::Make::Builder', 'add_circle');

# ── Ellipse ──────────────────────────────────────────────

isa_ok($b->add_ellipse(fill_colour => '#f39c12', x => 300, y => 500, w => 100, h => 60),
    'PDF::Make::Builder', 'add_ellipse');

# ── Pie ──────────────────────────────────────────────────

isa_ok($b->add_pie(fill_colour => '#e67e22', x => 450, y => 500, r => 40, rx => 0, ry => 90),
    'PDF::Make::Builder', 'add_pie');

# ── Image ────────────────────────────────────────────────

$cy = $b->page->cursor_y;
isa_ok($b->add_image(image => 't/fixtures/images/test.jpg', w => 150),
    'PDF::Make::Builder', 'add_image JPEG');
ok($b->page->cursor_y < $cy, 'cursor advances after image');

isa_ok($b->add_image(image => 't/fixtures/images/test.png', w => 100),
    'PDF::Make::Builder', 'add_image PNG');

# ── Multiple shapes on same page ─────────────────────────

$b->add_page;
for my $i (1..5) {
    $b->add_box(w => 50 + $i * 30, h => 15, fill_colour => sprintf('#%02x%02x%02x', $i*40, 100, 200));
}
ok($b->page_count == 2, 'two pages after adding shapes');

# ── Save and verify ──────────────────────────────────────

$b->save;
ok(-f $tmpfile, 'shapes PDF created');
open my $fh, '<:raw', $tmpfile;
my $bytes = do { local $/; <$fh> };
like($bytes, qr/%PDF/, 'valid PDF header');
like($bytes, qr/%%EOF/, 'valid PDF trailer');
ok(length($bytes) > 500, 'PDF has substantial content');

done_testing;

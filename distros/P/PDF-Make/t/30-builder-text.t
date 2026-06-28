#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }
BEGIN { use_ok('PDF::Make::Builder::Font') }

my $tmpfile = tmpnam() . '.pdf';
END { unlink $tmpfile if $tmpfile && -f $tmpfile }

# ── Font tests ───────────────────────────────────────────

my $font = PDF::Make::Builder::Font->new(
    family => 'Helvetica', size => 12, colour => '#333',
);
ok($font, 'Font created');
is($font->family, 'Helvetica', 'font family');
is($font->size, 12, 'font size');
is($font->colour, '#333', 'font colour');

ok($font->space_width > 0, 'space_width > 0');
ok($font->measure_text('Hello') > 0, 'measure_text > 0');
ok($font->measure_word('test') > 0, 'measure_word > 0');
ok($font->effective_line_height > 0, 'effective_line_height > 0');

my ($r, $g, $blue) = $font->hex_to_rgb('#ff0000');
cmp_ok($r, '==', 1, 'hex red R=1');
cmp_ok($g, '==', 0, 'hex red G=0');
cmp_ok($blue, '==', 0, 'hex red B=0');

my ($r2, $g2, $blue2) = $font->hex_to_rgb('#00ff00');
cmp_ok($g2, '==', 1, 'hex green G=1');

my @fams = PDF::Make::Builder::Font->families;
ok(scalar @fams >= 3, 'families returns 3+ families');
ok((grep { $_ eq 'Helvetica' } @fams), 'Helvetica in families');

# ── Text rendering ───────────────────────────────────────

my $b = PDF::Make::Builder->new(file_name => $tmpfile);
$b->add_page(page_size => 'Letter');

my $cursor_before = $b->page->cursor_y;
$b->add_text(text => 'Simple paragraph of text.');
my $cursor_after = $b->page->cursor_y;
ok($cursor_after < $cursor_before, 'cursor advances after add_text');

# Font override
$b->add_text(text => 'Bold courier text',
    font => { family => 'Courier', size => 14, colour => '#0000ff' });
ok($b->page->cursor_y < $cursor_after, 'cursor advances with font override');

# ── Headings ─────────────────────────────────────────────

for my $level (1..6) {
    my $method = "add_h$level";
    isa_ok($b->$method(text => "Heading $level"), 'PDF::Make::Builder', "add_h$level returns self");
}

# ── Text overflow (page break) ───────────────────────────

my $b2file = tmpnam() . '.pdf';
END { unlink $b2file if $b2file && -f $b2file }

my $b2 = PDF::Make::Builder->new(file_name => $b2file);
$b2->add_page(page_size => 'A4');
my $long = 'This is a test sentence that will be repeated many times to force a page overflow. ' x 500;
$b2->add_text(text => $long, overflow => 1);
ok($b2->page_count > 1, 'text overflow created multiple pages');

# ── Save and verify ──────────────────────────────────────

$b->save;
ok(-f $tmpfile, 'text PDF created');
open my $fh, '<:raw', $tmpfile;
my $bytes = do { local $/; <$fh> };
like($bytes, qr/Simple paragraph/, 'PDF contains text');
like($bytes, qr/%PDF/, 'valid PDF header');

done_testing;

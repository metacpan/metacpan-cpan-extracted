#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 25;

BEGIN {
    use_ok('PDF::Make::Builder');
    use_ok('PDF::Make::Extract::Result');
    use_ok('PDF::Make::Extract::Block');
    use_ok('PDF::Make::Extract::Line');
    use_ok('PDF::Make::Extract::Word');
}

# ── 1: Extract from hello_world.pdf ─────────────────────

my $b = PDF::Make::Builder->new(file_name => '/tmp/textract_test.pdf');
my $r = $b->extract_structured('t/fixtures/hello_world.pdf', page => 0);

isa_ok($r, 'PDF::Make::Extract::Result', 'result object');
ok($r->block_count > 0, 'has blocks');

my @blocks = $r->blocks;
isa_ok($blocks[0], 'PDF::Make::Extract::Block', 'first block');

my @lines = $blocks[0]->lines;
ok(scalar @lines > 0, 'block has lines');
isa_ok($lines[0], 'PDF::Make::Extract::Line', 'first line');

my @words = $lines[0]->words;
ok(scalar @words > 0, 'line has words');
isa_ok($words[0], 'PDF::Make::Extract::Word', 'first word');

# ── 2: Word properties ──────────────────────────────────

my $w = $words[0];
like($w->text, qr/Hello/, 'first word is Hello');
ok($w->x0 > 0, 'x0 > 0');
ok($w->y0 > 0, 'y0 > 0');
ok($w->x1 > $w->x0, 'x1 > x0');
ok($w->width > 0, 'width > 0');
ok($w->height > 0, 'height > 0');
cmp_ok($w->font_size, '==', 24, 'font size is 24');

# ── 3: Line properties ──────────────────────────────────

ok($lines[0]->baseline > 0, 'baseline > 0');
ok($lines[0]->word_count >= 2, 'line has >= 2 words');
my ($lx0, $ly0, $lx1, $ly1) = $lines[0]->bbox;
ok($lx1 > $lx0, 'line bbox width > 0');

# ── 4: text_positions flat list ──────────────────────────

my @pos = $r->text_positions;
ok(scalar @pos >= 2, 'text_positions has items');
ok(exists $pos[0]->{text} && exists $pos[0]->{x} && exists $pos[0]->{font_size},
   'text_positions has expected keys');

# ── 5: to_string ────────────────────────────────────────

my $str = $r->to_string;
like($str, qr/Hello.*World/s, 'to_string contains Hello World');

done_testing;

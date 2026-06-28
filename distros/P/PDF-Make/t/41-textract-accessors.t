#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('PDF::Make::Builder');
    use_ok('PDF::Make::Extract::Result');
    use_ok('PDF::Make::Extract::Block');
    use_ok('PDF::Make::Extract::Line');
    use_ok('PDF::Make::Extract::Word');
}

SKIP: {
    skip 't/fixtures/hello_world.pdf not found', 30 unless -f 't/fixtures/hello_world.pdf';

    my $b = PDF::Make::Builder->new(file_name => '/tmp/dummy_extract.pdf');
    my $r = $b->extract_structured('t/fixtures/hello_world.pdf', page => 0);

    # ── Result ───────────────────────────────────────────

    isa_ok($r, 'PDF::Make::Extract::Result');
    ok($r->block_count > 0, 'block_count > 0');

    my $str = $r->to_string;
    like($str, qr/Hello/, 'to_string contains Hello');

    my @pos = $r->text_positions;
    ok(scalar @pos >= 1, 'text_positions returns items');
    ok(exists $pos[0]->{text}, 'position has text key');
    ok(exists $pos[0]->{x}, 'position has x key');
    ok(exists $pos[0]->{y}, 'position has y key');
    ok(exists $pos[0]->{w}, 'position has w key');
    ok(exists $pos[0]->{h}, 'position has h key');
    ok(exists $pos[0]->{font_size}, 'position has font_size key');
    ok(exists $pos[0]->{baseline}, 'position has baseline key');

    # ── Block accessors ──────────────────────────────────

    my @blocks = $r->blocks;
    my $block = $blocks[0];
    isa_ok($block, 'PDF::Make::Extract::Block');

    ok(defined $block->x0, 'block x0 defined');
    ok(defined $block->y0, 'block y0 defined');
    ok($block->x1 > $block->x0, 'block x1 > x0');
    my ($bx0, $by0, $bx1, $by1) = $block->bbox;
    is($bx0, $block->x0, 'bbox x0 matches accessor');
    ok($block->line_count > 0, 'block line_count > 0');

    my $bstr = $block->to_string;
    like($bstr, qr/Hello/, 'block to_string');

    # ── Line accessors ───────────────────────────────────

    my @lines = $block->lines;
    my $line = $lines[0];
    isa_ok($line, 'PDF::Make::Extract::Line');

    ok(defined $line->x0, 'line x0 defined');
    ok(defined $line->y0, 'line y0 defined');
    ok($line->x1 > $line->x0, 'line x1 > x0');
    ok($line->baseline > 0, 'line baseline > 0');
    my ($lx0, $ly0, $lx1, $ly1) = $line->bbox;
    is($lx0, $line->x0, 'line bbox matches accessor');
    ok($line->word_count >= 1, 'line word_count >= 1');

    my $lstr = $line->to_string;
    like($lstr, qr/Hello/, 'line to_string');

    # ── Word accessors ───────────────────────────────────

    my @words = $line->words;
    my $word = $words[0];
    isa_ok($word, 'PDF::Make::Extract::Word');

    like($word->text, qr/Hello/, 'word text');
    ok($word->x0 >= 0, 'word x0 >= 0');
    ok($word->width > 0, 'word width > 0');
    ok($word->height > 0, 'word height > 0');
    ok($word->font_size > 0, 'word font_size > 0');
    my ($wx0, $wy0, $wx1, $wy1) = $word->bbox;
    is($wx0, $word->x0, 'word bbox matches accessor');
}

done_testing;

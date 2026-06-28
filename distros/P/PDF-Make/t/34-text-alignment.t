#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

my $f = tmpnam() . '.pdf';
END { unlink $f if $f && -f $f }

my $b = PDF::Make::Builder->new(file_name => $f);
$b->add_page(page_size => 'Letter');

# ── Center alignment ────────────────────────────────────

my $cy = $b->page->cursor_y;
$b->add_text(text => 'This text should be centered on the page', align => 'center');
ok($b->page->cursor_y < $cy, 'center text advances cursor');

# ── Right alignment ─────────────────────────────────────

$cy = $b->page->cursor_y;
$b->add_text(text => 'This text should be right-aligned', align => 'right');
ok($b->page->cursor_y < $cy, 'right text advances cursor');

# ── Indented text ────────────────────────────────────────

$cy = $b->page->cursor_y;
$b->add_text(text => 'This paragraph has a first-line indent applied to it.', indent => 4);
ok($b->page->cursor_y < $cy, 'indented text advances cursor');

# ── Pad character (dot leader) ───────────────────────────

$cy = $b->page->cursor_y;
$b->add_text(text => 'Chapter 1', pad => '.', end_w => 40);
ok($b->page->cursor_y < $cy, 'pad text advances cursor');

# ── Line height override ────────────────────────────────

$cy = $b->page->cursor_y;
$b->add_text(text => 'Custom line height', font => { line_height => 24, size => 10 });
ok($b->page->cursor_y < $cy, 'line_height override advances cursor');

# ── Font family override ────────────────────────────────

$b->add_text(text => 'Courier text', font => { family => 'Courier', size => 11 });
ok(1, 'Courier font override renders');

$b->add_text(text => 'Times text', font => { family => 'Times', size => 11 });
ok(1, 'Times font override renders');

# ── Long text with word wrap ─────────────────────────────

$b->add_text(text => 'This is a longer paragraph that should wrap across multiple lines. ' x 5);
ok(1, 'multi-line word-wrapped text renders');

# ── All three alignments on same page ────────────────────

$b->add_text(text => 'Left aligned (default)');
$b->add_text(text => 'Center aligned', align => 'center');
$b->add_text(text => 'Right aligned', align => 'right');
ok(1, 'three alignments on same page');

# ── Column text flow ────────────────────────────────────

my $f2 = tmpnam() . '.pdf';
END { unlink $f2 if $f2 && -f $f2 }
my $b2 = PDF::Make::Builder->new(file_name => $f2);
$b2->add_page(page_size => 'Letter', columns => 2);
$b2->add_text(text => ('Column flow test word. ' x 300), overflow => 1);
ok($b2->page_count >= 1, 'column text flow works');
$b2->save;
ok(-f $f2, 'column flow PDF created');

# ── Save and verify ──────────────────────────────────────

$b->save;
ok(-f $f, 'text alignment PDF created');
open my $fh, '<:raw', $f;
my $bytes = do { local $/; <$fh> };
like($bytes, qr/centered/, 'PDF contains centered text');
like($bytes, qr/right-aligned/, 'PDF contains right-aligned text');
like($bytes, qr/indent/, 'PDF contains indented text');

done_testing;

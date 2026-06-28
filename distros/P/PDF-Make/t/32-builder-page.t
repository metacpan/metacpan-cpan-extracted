#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }
BEGIN { use_ok('PDF::Make::Builder::Page') }

# ── Page dimensions ──────────────────────────────────────

my @a4 = PDF::Make::Builder::Page::page_dimensions('A4');
is_deeply(\@a4, [595, 842], 'A4 dimensions');

my @letter = PDF::Make::Builder::Page::page_dimensions('Letter');
is_deeply(\@letter, [612, 792], 'Letter dimensions');

my @legal = PDF::Make::Builder::Page::page_dimensions('Legal');
is_deeply(\@legal, [612, 1008], 'Legal dimensions');

my @a3 = PDF::Make::Builder::Page::page_dimensions('A3');
is_deeply(\@a3, [842, 1191], 'A3 dimensions');

my @unknown = PDF::Make::Builder::Page::page_dimensions('Unknown');
is_deeply(\@unknown, [595, 842], 'unknown falls back to A4');

# ── Page management ──────────────────────────────────────

my $tmpfile = tmpnam() . '.pdf';
END { unlink $tmpfile if $tmpfile && -f $tmpfile }

my $b = PDF::Make::Builder->new(file_name => $tmpfile);

$b->add_page(page_size => 'Letter');
is($b->page_count, 1, '1 page after add_page');

$b->add_page(page_size => 'A4');
is($b->page_count, 2, '2 pages');

$b->add_page;
is($b->page_count, 3, '3 pages');

# ── Page cursor ──────────────────────────────────────────

$b->open_page(1);
my $page = $b->page;
ok($page, 'open_page returns page');

my $top = $page->top_y;
my $bot = $page->bottom_y;
ok($top > $bot, 'top_y > bottom_y');
ok($page->remaining_height > 0, 'remaining_height > 0');
ok($page->width > 0, 'width > 0');
ok($page->content_x > 0, 'content_x > 0');
ok($page->cursor_y > 0, 'cursor_y > 0');

my $before = $page->cursor_y;
$page->advance_y(50);
is($page->cursor_y, $before - 50, 'advance_y moves cursor down');

# ── remove_page ──────────────────────────────────────────

$b->remove_page(1);
is($b->page_count, 2, 'page count after remove');

# ── rotate_page ──────────────────────────────────────────

isa_ok($b->rotate_page(0, 90), 'PDF::Make::Builder', 'rotate_page returns self');

# ── duplicate_page ───────────────────────────────────────

$b->duplicate_page(0);
is($b->page_count, 3, 'page count after duplicate');

# ── move_page ────────────────────────────────────────────

isa_ok($b->move_page(2, 0), 'PDF::Make::Builder', 'move_page returns self');

# ── Page background ──────────────────────────────────────

my $b2file = tmpnam() . '.pdf';
END { unlink $b2file if $b2file && -f $b2file }

my $b2 = PDF::Make::Builder->new(file_name => $b2file);
$b2->add_page(page_size => 'A4', background => '#f0f0f0');
$b2->add_text(text => 'On coloured background');
$b2->save;
ok(-f $b2file, 'background page PDF created');

# ── Headers and Footers ─────────────────────────────────

my $b3file = tmpnam() . '.pdf';
END { unlink $b3file if $b3file && -f $b3file }

my $b3 = PDF::Make::Builder->new(file_name => $b3file);
$b3->add_page_header(show_page_num => 'right', page_num_text => 'Page {num}');
$b3->add_page_footer(show_page_num => 'center', page_num_text => '- {num} -');
$b3->add_page(page_size => 'Letter');
$b3->add_text(text => 'Page with header and footer');
$b3->add_page;
$b3->add_text(text => 'Second page');
$b3->save;

ok(-f $b3file, 'header/footer PDF created');
open my $fh, '<:raw', $b3file;
my $bytes = do { local $/; <$fh> };
like($bytes, qr/Page 1/, 'header has Page 1');
like($bytes, qr/Page 2/, 'header has Page 2');
like($bytes, qr/- 1 -/, 'footer has - 1 -');
like($bytes, qr/- 2 -/, 'footer has - 2 -');

# ── Remove header/footer ────────────────────────────────

isa_ok($b3->remove_page_header, 'PDF::Make::Builder', 'remove_page_header');
isa_ok($b3->remove_page_footer, 'PDF::Make::Builder', 'remove_page_footer');

# ── TOC ──────────────────────────────────────────────────

my $b4file = tmpnam() . '.pdf';
END { unlink $b4file if $b4file && -f $b4file }

my $b4 = PDF::Make::Builder->new(file_name => $b4file);
$b4->add_toc(title => 'Contents');
$b4->add_page;
$b4->add_h1(text => 'Chapter 1', toc => 1);
$b4->add_text(text => 'Body text');
$b4->save;
ok(-f $b4file, 'TOC PDF created');
ok(-s $b4file > 100, 'TOC PDF has content');

done_testing;

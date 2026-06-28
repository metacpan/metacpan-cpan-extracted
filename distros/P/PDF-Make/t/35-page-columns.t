#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }
BEGIN { use_ok('PDF::Make::Builder::Page') }

# ── Two-column layout ───────────────────────────────────

my $f = tmpnam() . '.pdf';
END { unlink $f if $f && -f $f }

my $b = PDF::Make::Builder->new(file_name => $f);
$b->add_page(page_size => 'Letter', columns => 2, padding => 36);

my $page = $b->page;
is($page->columns, 2, '2 columns set');

# Column width should be less than full page
my $col_w = $page->width;
ok($col_w < 500, "column width $col_w < full page");
ok($col_w > 200, "column width $col_w > minimum");

# Content X for column 1
my $cx1 = $page->content_x;
is($cx1, 36, 'col 1 content_x = padding');

# Has next column
ok($page->has_next_column, 'col 1 has_next_column');

# Move to column 2
ok($page->next_column, 'next_column returns true');
my $cx2 = $page->content_x;
ok($cx2 > 280, "col 2 content_x ($cx2) > 280");
ok(!$page->has_next_column, 'col 2 has no next column');

# Reset
$page->reset_columns;
is($page->content_x, 36, 'reset_columns returns to col 1');
ok($page->has_next_column, 'after reset, has_next_column again');

# ── Three-column layout ─────────────────────────────────

my $f2 = tmpnam() . '.pdf';
END { unlink $f2 if $f2 && -f $f2 }

my $b2 = PDF::Make::Builder->new(file_name => $f2);
$b2->add_page(page_size => 'A4', columns => 3, padding => 20);
my $p2 = $b2->page;

is($p2->columns, 3, '3 columns set');
my $w3 = $p2->width;
ok($w3 < 200, "3-col width $w3 < 200");

ok($p2->has_next_column, 'col 1 of 3 has next');
$p2->next_column;
ok($p2->has_next_column, 'col 2 of 3 has next');
$p2->next_column;
ok(!$p2->has_next_column, 'col 3 of 3 has no next');

# ── Column overflow to new page ──────────────────────────

my $f3 = tmpnam() . '.pdf';
END { unlink $f3 if $f3 && -f $f3 }

my $b3 = PDF::Make::Builder->new(file_name => $f3);
$b3->add_page(page_size => 'Letter', columns => 2, padding => 36);
$b3->add_text(text => ('Lorem ipsum dolor sit amet. ' x 500), overflow => 1);
$b3->save;

ok($b3->page_count > 1, 'column overflow created multiple pages');
my $pages = $b3->pages;
for my $i (0 .. $#$pages) {
    is($pages->[$i]->columns, 2, "page $i has 2 columns");
}
ok(-f $f3, 'column overflow PDF created');

done_testing;

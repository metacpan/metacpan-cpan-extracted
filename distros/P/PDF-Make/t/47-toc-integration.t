#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }
BEGIN { use_ok('PDF::Make::Builder::TOC') }

# ── TOC with headings ───────────────────────────────────

my $f = tmpnam() . '.pdf';
END { unlink $f if $f && -f $f }

my $b = PDF::Make::Builder->new(file_name => $f);

# Enable TOC
$b->add_toc(title => 'Contents', title_padding => 15, level_indent => 3);
ok($b->toc, 'TOC created');

# Page 1
$b->add_page(page_size => 'Letter');
$b->add_h1(text => 'Chapter 1: Introduction', toc => 1);
$b->add_text(text => 'Introduction content. ' x 10);
$b->add_h2(text => 'Section 1.1: Background', toc => 1);
$b->add_text(text => 'Background material. ' x 8);
$b->add_h3(text => 'Subsection 1.1.1', toc => 1);
$b->add_text(text => 'Details here. ' x 5);

# Page 2
$b->add_page;
$b->add_h1(text => 'Chapter 2: Methods', toc => 1);
$b->add_text(text => 'Methods description. ' x 10);
$b->add_h2(text => 'Section 2.1: Approach', toc => 1);
$b->add_text(text => 'Approach details. ' x 8);

# Page 3
$b->add_page;
$b->add_h1(text => 'Chapter 3: Results', toc => 1);
$b->add_text(text => 'Results text. ' x 10);

# Check TOC entries were collected
my $toc = $b->toc;
my $entries = $toc->entries;
ok(scalar @$entries >= 6, 'TOC has 6+ entries');

# Check entry structure
my $e1 = $entries->[0];
is($e1->{text}, 'Chapter 1: Introduction', 'first entry text');
ok(defined $e1->{page_num}, 'first entry has page_num');
is($e1->{level}, 1, 'H1 is level 1');

my $e2 = $entries->[1];
is($e2->{level}, 2, 'H2 is level 2');

my $e3 = $entries->[2];
is($e3->{level}, 3, 'H3 is level 3');

# Save (triggers TOC render)
$b->save;
ok(-f $f, 'TOC PDF created');
ok(-s $f > 1000, 'PDF has content');

open my $fh, '<:raw', $f;
my $bytes = do { local $/; <$fh> };
like($bytes, qr/Contents/, 'PDF has TOC title');
like($bytes, qr/Chapter 1/, 'PDF has Chapter 1');
like($bytes, qr/Chapter 2/, 'PDF has Chapter 2');
like($bytes, qr/Chapter 3/, 'PDF has Chapter 3');

# ── TOC with custom font args ───────────────────────────

my $f2 = tmpnam() . '.pdf';
END { unlink $f2 if $f2 && -f $f2 }

my $b2 = PDF::Make::Builder->new(file_name => $f2);
$b2->add_toc(
    title           => 'Table of Contents',
    title_font_args => { family => 'Times', size => 18, colour => '#000' },
    font_args       => { size => 9 },
    padding         => 3,
    level_indent    => 4,
);
$b2->add_page(page_size => 'A4');
$b2->add_h1(text => 'First Chapter', toc => 1);
$b2->add_text(text => 'Content.');
$b2->add_h2(text => 'First Section', toc => 1);
$b2->add_text(text => 'More content.');
$b2->save;
ok(-f $f2, 'custom-styled TOC PDF created');

# ── TOC outline method directly ──────────────────────────

my $toc2 = PDF::Make::Builder::TOC->new(title => 'Test TOC');
$toc2->outline(undef, 1, text => 'Entry 1', page_num => 1);
$toc2->outline(undef, 2, text => 'Entry 1.1', page_num => 1);
$toc2->outline(undef, 1, text => 'Entry 2', page_num => 2);

my $entries2 = $toc2->entries;
is(scalar @$entries2, 3, 'manual TOC has 3 entries');
is($entries2->[0]{text}, 'Entry 1', 'manual entry 1 text');
is($entries2->[1]{level}, 2, 'manual entry 2 level');
is($entries2->[2]{page_num}, 2, 'manual entry 3 page_num');

# ── TOC from fixture ────────────────────────────────────

SKIP: {
    skip 'toc_source.pdf fixture not found', 2 unless -f 't/fixtures/fixtures/toc_source.pdf';

    ok(-f 't/fixtures/fixtures/toc_source.pdf', 'TOC fixture exists');
    ok(-s 't/fixtures/fixtures/toc_source.pdf' > 1000, 'TOC fixture has content');
}

# ── TOC edge cases: undef entry fields, non-numeric page_num ─
{
    my $f3 = tmpnam() . '.pdf';
    END { unlink $f3 if $f3 && -f $f3 }

    my $b3 = PDF::Make::Builder->new(file_name => $f3);
    $b3->add_toc(
        font_args => { colour => '#555' },  # exercises colour fallback
    );
    my $t3 = $b3->toc;
    # Entry with undef text
    $t3->outline(undef, 1, text => undef,        page_num => undef);
    # Entry with non-numeric page_num (skips add_link branch)
    $t3->outline(undef, 1, text => 'Appendix A', page_num => 'A');
    # Entry with page_num 0 (also skips add_link)
    $t3->outline(undef, 1, text => 'Frontmatter', page_num => 0);
    # Long text so dot leaders disappear (leader_end < leader_start)
    $t3->outline(undef, 1,
        text => 'X' x 200,
        page_num => undef);

    $b3->add_page(page_size => 'Letter');
    $b3->save;
    ok(-f $f3, 'TOC with edge-case entries saved');
}

# ── TOC with out-of-range page_index falls to current page ─
{
    my $f4 = tmpnam() . '.pdf';
    END { unlink $f4 if $f4 && -f $f4 }
    my $b4 = PDF::Make::Builder->new(file_name => $f4);
    $b4->add_toc(page_index => 99);
    # Entry with undef page_num so add_link isn't called
    $b4->toc->outline(undef, 1, text => 'Entry', page_num => undef);
    $b4->add_page(page_size => 'Letter');
    $b4->save;
    ok(-f $f4, 'TOC with out-of-range page_index saves');
}

# ── TOC render with no pages at all returns early ─────────
{
    no warnings 'once';
    my $toc_empty = PDF::Make::Builder::TOC->new;
    my $fake_builder = bless { _pages => [] }, 'FakeBuilder';
    no strict 'refs';
    *FakeBuilder::pages = sub { $_[0]->{_pages} };
    *FakeBuilder::page  = sub { undef };
    my $rv = eval { $toc_empty->render($fake_builder) };
    ok(!$@, 'render returns gracefully when no pages') or diag $@;
}

done_testing;

#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN {
    use_ok('PDF::Make::Builder');
    use_ok('PDF::Make::Import');
}

# ── Helper: build a small labeled PDF ────────────────────
sub make_source {
    my ($label, @texts) = @_;
    my $f = tmpnam() . "-$label.pdf";
    my $b = PDF::Make::Builder->new(file_name => $f);
    for my $t (@texts) {
        $b->add_page(page_size => 'Letter')
          ->add_h1(text => "$label: $t")
          ->add_text(text => "body for $label / $t");
    }
    $b->save;
    return $f;
}

# ── append_pdf: 2 sources, all pages ─────────────────────
{
    my $src_a = make_source('AAA', 'p1', 'p2');
    my $src_b = make_source('BBB', 'q1');

    my $out = tmpnam() . '-merged.pdf';
    my $b   = PDF::Make::Builder->new(file_name => $out);
    $b->append_pdf($src_a);
    $b->append_pdf($src_b);
    $b->save;

    ok(-f $out, 'merged PDF created');
    is($b->page_count, 3, 'merged has 2+1 = 3 pages');

    open my $fh, '<:raw', $out or die $!;
    my $bytes = do { local $/; <$fh> };
    like($bytes, qr/AAA: p1/, 'page 1 text from source A');
    like($bytes, qr/AAA: p2/, 'page 2 text from source A');
    like($bytes, qr/BBB: q1/, 'page 3 text from source B');

    unlink $src_a, $src_b, $out;
}

# ── append_pdf: selected pages only ──────────────────────
{
    my $src = make_source('SEL', 'alpha', 'beta', 'gamma');
    my $out = tmpnam() . '-sel.pdf';
    my $b   = PDF::Make::Builder->new(file_name => $out);
    $b->append_pdf($src, pages => [0, 2]);  # alpha + gamma, skip beta
    $b->save;

    is($b->page_count, 2, 'selected import yields 2 pages');

    open my $fh, '<:raw', $out or die $!;
    my $bytes = do { local $/; <$fh> };
    like($bytes,   qr/SEL: alpha/, 'alpha present');
    like($bytes,   qr/SEL: gamma/, 'gamma present');
    unlike($bytes, qr/SEL: beta/,  'beta skipped');

    unlink $src, $out;
}

# ── Builder->merge class method ──────────────────────────
{
    my $s1 = make_source('M1', 'one');
    my $s2 = make_source('M2', 'two');
    my $s3 = make_source('M3', 'three');

    my $out = tmpnam() . '-classmerge.pdf';
    my $b   = PDF::Make::Builder->merge($out, $s1, $s2, $s3);

    ok(-f $out, 'class merge produced file');
    is($b->page_count, 3, 'class merge pages');

    open my $fh, '<:raw', $out or die $!;
    my $bytes = do { local $/; <$fh> };
    like($bytes, qr/M1: one/,   'M1 present');
    like($bytes, qr/M2: two/,   'M2 present');
    like($bytes, qr/M3: three/, 'M3 present');

    unlink $s1, $s2, $s3, $out;
}

# ── Mixing: native pages + appended pages ────────────────
{
    my $src = make_source('ADD', 'existing');
    my $out = tmpnam() . '-mixed.pdf';
    my $b   = PDF::Make::Builder->new(file_name => $out);
    $b->add_page(page_size => 'Letter')->add_text(text => 'front matter');
    $b->append_pdf($src);
    $b->add_page(page_size => 'Letter')->add_text(text => 'back matter');
    $b->save;

    is($b->page_count, 3, 'mixed: native + imported + native = 3');

    open my $fh, '<:raw', $out or die $!;
    my $bytes = do { local $/; <$fh> };
    like($bytes, qr/front matter/,  'front native page present');
    like($bytes, qr/ADD: existing/, 'middle imported page present');
    like($bytes, qr/back matter/,   'back native page present');

    unlink $src, $out;
}

# ── Round-trip: the merged PDF can be re-parsed ──────────
{
    my $src = make_source('RT', 'round', 'trip');
    my $out = tmpnam() . '-rt.pdf';
    my $b   = PDF::Make::Builder->new(file_name => $out);
    $b->append_pdf($src);
    $b->save;

    my $b2 = PDF::Make::Builder->open_existing($out);
    is($b2->page_count, 2, 're-opened merged PDF has 2 pages');

    unlink $src, $out;
}

# ── append_pdf: missing file dies ────────────────────────
{
    my $b = PDF::Make::Builder->new(file_name => tmpnam() . '.pdf');
    eval { $b->append_pdf('/nonexistent/path.pdf') };
    like($@, qr/not found/, 'missing file produces error');
}

# ── append_pdf: out-of-range page dies ───────────────────
{
    my $src = make_source('OOR', 'only');
    my $b   = PDF::Make::Builder->new(file_name => tmpnam() . '.pdf');
    eval { $b->append_pdf($src, pages => [5]) };
    like($@, qr/out of range/, 'out-of-range page index dies');
    unlink $src;
}

# ── Resource dedup via shared import ctx (white-box) ─────
{
    my $src = make_source('DD', 'a', 'b', 'c');
    my $out = tmpnam() . '-dd.pdf';
    my $b   = PDF::Make::Builder->new(file_name => $out);
    $b->append_pdf($src);  # three pages sharing the same Helvetica font
    $b->save;

    my $b2 = PDF::Make::Builder->open_existing($out);
    is($b2->page_count, 3, 'three imported pages');

    unlink $src, $out;
}

done_testing;

#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

# ── Center alignment ────────────────────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_text(text => 'Centered text', align => 'center');
    $b->save;
    ok(-f $f, 'center-aligned text');
    unlink $f;
}

# ── Right alignment ─────────────────────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_text(text => 'Right-aligned text', align => 'right');
    $b->save;
    ok(-f $f, 'right-aligned text');
    unlink $f;
}

# ── Pad character (TOC-style dot leader) ────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_text(text => 'Chapter 1', pad => '.');
    $b->add_text(text => 'Chapter 2', pad => '.');
    $b->save;
    ok(-f $f, 'text with pad char');
    unlink $f;
}

# ── Long text with word wrapping and line spacing ───────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');

    # Long text to force word wrapping
    my $long = 'This is a test of word wrapping in the Builder text component. ' x 20;
    $b->add_text(text => $long, spacing => 4, indent => 4);
    $b->save;
    ok(-f $f, 'long wrapping text with line_spacing');
    unlink $f;
}

# ── Text with zero indent ──────────────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_text(text => 'No indent', indent => 0);
    $b->save;
    ok(-f $f, 'text with zero indent');
    unlink $f;
}

# ── Text with font overrides (triggers _resolve_font) ──

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');

    # With font override hash
    $b->add_text(text => 'Bold text', font => { bold => 1, size => 16 });
    $b->add_text(text => 'Italic text', font => { italic => 1 });
    $b->add_text(text => 'Coloured text', font => { colour => '#ff0000' });

    # Without font override (nil branch of _resolve_font)
    $b->add_text(text => 'Default font');

    $b->save;
    ok(-f $f, 'text with font overrides');
    unlink $f;
}

# ── Text page overflow (triggers new page) ──────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');

    # Fill entire page to trigger overflow
    for (1..120) {
        $b->add_text(text => "Line $_ with some content to fill the page and trigger overflow.");
    }

    $b->save;
    ok(-f $f, 'text overflow to new page');
    ok(-s $f > 5000, 'overflow PDF has substantial content');
    unlink $f;
}

# ── Text in columns (triggers column overflow) ──────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->set_columns(2, gap => 20);

    for (1..60) {
        $b->add_text(text => "Column line $_. " x 3);
    }

    $b->save;
    ok(-f $f, 'column text overflow');
    unlink $f;
}

# ── Headings H1-H6 ─────────────────────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_h1(text => 'Heading 1');
    $b->add_h2(text => 'Heading 2');
    $b->add_h3(text => 'Heading 3');
    $b->add_h4(text => 'Heading 4');
    $b->add_h5(text => 'Heading 5');
    $b->add_h6(text => 'Heading 6');
    $b->save;
    ok(-f $f, 'all heading levels');
    unlink $f;
}

done_testing;

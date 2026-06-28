#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

# ── add_page with background colour ────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter', background => '#ff0000');
    $b->add_text(text => 'Red background page');
    $b->save;
    ok(-f $f, 'page with background colour');
    open my $fh, '<:raw', $f; my $bytes = do { local $/; <$fh> }; close $fh;
    like($bytes, qr/%PDF/, 'valid PDF with bg');
    unlink $f;
}

# ── add_outline with parent ─────────────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_text(text => 'Chapter 1');
    $b->add_outline('Chapter 1', page => 0);
    $b->add_outline('Section 1.1', page => 0, parent => 'Chapter 1');
    $b->add_outline('Orphan', page => 0, parent => 'Nonexistent');
    $b->save;
    ok(-f $f, 'outline with parent');
    unlink $f;
}

# ── add_link with rect ──────────────────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_text(text => 'Click here');

    # URL link with rect
    eval { $b->add_link(url => 'https://example.com',
                        rect => [72, 700, 272, 720]) };
    ok(!$@, 'add_link URL with rect') or diag $@;

    # Internal link to page
    $b->add_page;
    $b->add_text(text => 'Page 2');
    eval { $b->add_link(page => 0, dest => 'Fit',
                        rect => [72, 700, 272, 720]) };
    ok(!$@, 'add_link internal GoTo') or diag $@;

    $b->save;
    ok(-f $f, 'link PDF created');
    unlink $f;
}

# ── add_field branches (combo, listbox, button, options) ─

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');

    # Combo field with options
    eval { $b->add_field(type => 'combo', name => 'combo1',
                         rect => [72, 700, 250, 720],
                         options => [['Display A', 'a'], ['Display B', 'b']]) };
    ok(!$@, 'combo field with options') or diag $@;

    # Listbox field
    eval { $b->add_field(type => 'listbox', name => 'list1',
                         rect => [72, 650, 250, 690],
                         options => ['One', 'Two', 'Three']) };
    ok(!$@, 'listbox field') or diag $@;

    # Button field
    eval { $b->add_field(type => 'button', name => 'btn1',
                         rect => [72, 600, 200, 630],
                         caption => 'Submit') };
    ok(!$@, 'button field') or diag $@;

    # Text field with readonly, required, da
    eval { $b->add_field(type => 'text', name => 'ro_field',
                         rect => [72, 550, 250, 570],
                         readonly => 1, required => 1,
                         da => '/Helv 12 Tf 0 g') };
    ok(!$@, 'text field with readonly/required/da') or diag $@;

    $b->save;
    ok(-f $f, 'form fields PDF');
    unlink $f;
}

# ── add_field (structured mode) unknown type ───────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    eval { $b->add_field(type => 'bogus_type', name => 'bad_field') };
    ok($@, 'unknown field type dies');
    unlink $f if -f $f;
}

# ── remove_page: remove all pages ──────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_page;
    eval { $b->remove_page(1) };
    ok(!$@, 'remove page 1');
    eval { $b->remove_page(0) };
    ok(!$@, 'remove page 0 (last page)');
    unlink $f if -f $f;
}

# ── rotate_page: 0, 90, 180, 270 ──────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');  # 612 x 792
    $b->add_text(text => 'Rotation test');

    # 90 degrees - should swap width/height
    eval { $b->rotate_page(0, 90) };
    ok(!$@, 'rotate 90') or diag $@;

    # 180 degrees - should NOT swap
    eval { $b->rotate_page(0, 180) };
    ok(!$@, 'rotate 180') or diag $@;

    # 270 degrees - should swap again
    eval { $b->rotate_page(0, 270) };
    ok(!$@, 'rotate 270') or diag $@;

    $b->save;
    ok(-f $f, 'rotated PDF created');
    unlink $f;
}

# ── save without TOC/encrypt/signature ──────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_text(text => 'Minimal save');
    $b->save;
    ok(-f $f, 'minimal save (no TOC/encrypt/sig)');
    unlink $f;
}

# ── save with .pdf extension already present ────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page;
    $b->add_text(text => 'Extension test');
    $b->save;
    ok(-f $f, 'save with .pdf extension');
    unlink $f;
}

# ── add_page_header/footer with pages ───────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');

    eval { $b->add_page_header(h => 30, show_page_num => 'right') };
    ok(!$@, 'add_page_header') or diag $@;

    eval { $b->add_page_footer(h => 25, show_page_num => 'center') };
    ok(!$@, 'add_page_footer') or diag $@;

    $b->add_text(text => 'Body with header/footer');
    $b->add_page;
    $b->add_text(text => 'Page 2 inherits header/footer');
    $b->save;
    ok(-f $f, 'header/footer PDF');
    unlink $f;
}

# ── add_layer ───────────────────────────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    eval { $b->add_layer('MyLayer') };
    ok(!$@, 'add_layer') or diag $@;
    $b->add_text(text => 'Layer test');
    $b->save;
    ok(-f $f, 'layer PDF');
    unlink $f;
}

# ── encrypt ─────────────────────────────────────────────

{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_text(text => 'Encrypted doc');
    eval { $b->encrypt(password => 'secret', algorithm => 'AES-256') };
    ok(!$@, 'encrypt() callable') or diag $@;
    $b->save;
    ok(-f $f, 'encrypted PDF');
    unlink $f;
}

done_testing;

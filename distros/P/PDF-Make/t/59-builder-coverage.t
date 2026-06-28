#!/usr/bin/perl
# Coverage-targeted tests for PDF::Make::Builder accessors and branches.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

# ── Accessor methods without a current page return 0 ──────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    is($b->page_width,     0, 'page_width 0 without page');
    is($b->page_height,    0, 'page_height 0 without page');
    is($b->current_x,      0, 'current_x 0 without page');
    is($b->current_y,      0, 'current_y 0 without page');
    is($b->content_left,   0, 'content_left 0 without page');
    is($b->content_right,  0, 'content_right 0 without page');
    is($b->content_top,    0, 'content_top 0 without page');
    is($b->content_bottom, 0, 'content_bottom 0 without page');
    unlink $f if -f $f;
}

# ── Same accessors with a live page return something ──────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    ok($b->page_width  > 0, 'page_width > 0 with page');
    ok($b->page_height > 0, 'page_height > 0 with page');
    ok(defined $b->current_x, 'current_x defined');
    ok($b->current_y > 0, 'current_y > 0');
    ok($b->content_left   >= 0, 'content_left defined');
    ok($b->content_right  > 0,  'content_right > 0');
    ok($b->content_top    > 0,  'content_top > 0');
    ok($b->content_bottom >= 0, 'content_bottom defined');
    unlink $f if -f $f;
}

# ── cursor_move_to / cursor_advance_y ─────────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);

    # Without current page: both die
    eval { $b->cursor_move_to(10, 20) };
    like($@, qr/no current page/, 'cursor_move_to needs page');
    eval { $b->cursor_advance_y(5) };
    like($@, qr/no current page/, 'cursor_advance_y needs page');

    $b->add_page(page_size => 'A4');
    my $y_before = $b->current_y;
    isa_ok($b->cursor_move_to(50, 100), 'PDF::Make::Builder',
        'cursor_move_to returns self');
    is($b->current_y, 100, 'y moved to 100');

    # x-only update
    $b->cursor_move_to(30, undef);
    # y-only update
    $b->cursor_move_to(undef, 200);
    is($b->current_y, 200, 'y-only update');

    # cursor_advance_y with and without explicit $dy
    $b->cursor_advance_y(-10);
    is($b->current_y, 190, 'cursor_advance_y(-10)');
    $b->cursor_advance_y;
    is($b->current_y, 190, 'cursor_advance_y() keeps y');

    unlink $f if -f $f;
}

# ── add_lines with plain strings and hashrefs ─────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    isa_ok(
        $b->add_lines(
            'Plain string line',
            { text => 'Hashref line' },
            'Another plain line',
        ),
        'PDF::Make::Builder', 'add_lines returns self');
    eval { $b->save };
    ok(!$@, 'add_lines PDF saves') or diag $@;
    unlink $f if -f $f;
}

# ── add_link with named action and file variants ──────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');

    # Named action
    isa_ok(
        $b->add_link(
            rect   => [50, 50, 150, 70],
            action => 'NextPage',
        ), 'PDF::Make::Builder', 'add_link action returns self');

    # External PDF (GoToR)
    $b->add_link(
        rect       => [50, 100, 150, 120],
        file       => 'other.pdf',
        file_page  => 2,
        new_window => 1,
    );

    # Builder-coord variant (x/y/w/h)
    $b->add_link(x => 50, y => 200, w => 100, h => 20, page => 0);

    # Error: partial x/y/w/h
    eval { $b->add_link(x => 10, y => 20, page => 0) };
    like($@, qr/require x,y,w,h/, 'partial coords die');

    # Error: no destination at all
    eval { $b->add_link(rect => [0, 0, 10, 10]) };
    like($@, qr/requires url, page, action, or file/, 'no destination dies');

    eval { $b->save };
    ok(!$@, 'add_link variants PDF saves') or diag $@;
    unlink $f if -f $f;
}

# ── add_link on_page error path ───────────────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    eval { $b->add_link(on_page => 99, rect => [0, 0, 10, 10], page => 0) };
    like($@, qr/does not exist/, 'on_page out of range dies');
    unlink $f if -f $f;
}

# ── add_note visual mode: array of strings + hash lines ───
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    isa_ok(
        $b->add_note(
            lines => [
                'First line',
                { text => 'Bold italic', size => 12, colour => '#00f', italic => 1 },
                'Third line',
            ],
            x       => 72,
            w       => 300,
            h       => 70,
            padding => 10,
        ),
        'PDF::Make::Builder', 'add_note visual returns self');

    # text as array also triggers visual mode
    $b->add_note(text => ['Array text line 1', 'Line 2']);

    # error: add_note without current page (after remove)
    my $b2 = PDF::Make::Builder->new(file_name => tmpnam() . '.pdf');
    eval { $b2->add_note(lines => ['x'], y => 100) };
    like($@, qr/requires a current page/, 'add_note visual needs page');

    eval { $b->save };
    ok(!$@, 'add_note visual saves') or diag $@;
    unlink $f if -f $f;
}

# ── open_page error path ──────────────────────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page;
    eval { $b->open_page(99) };
    like($@, qr/does not exist/, 'open_page out of range dies');
    isa_ok($b->open_page(1), 'PDF::Make::Builder', 'open_page(1) ok');
    unlink $f if -f $f;
}

# ── set_columns without a page ────────────────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    eval { $b->set_columns(2) };
    like($@, qr/no current page/, 'set_columns needs page');
    unlink $f if -f $f;
}

# ── add_outline with parent and zoom options ──────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_outline('Chapter 1',
        page => 0, dest => 'XYZ', left => 10, top => 700, zoom => 1.5);
    isa_ok(
        $b->add_outline('Section 1.1', parent => 'Chapter 1', page => 0),
        'PDF::Make::Builder', 'add_outline with parent returns self');
    # parent_key missing → falls back to top-level branch
    $b->add_outline('Orphan', parent => 'NoSuchParent', page => 0);
    eval { $b->save };
    ok(!$@, 'outlines saved') or diag $@;
    unlink $f if -f $f;
}

# ── Builder::Image add() branch coverage ─────────────────
SKIP: {
    skip 'test image fixture missing', 5 unless -f 't/fixtures/images/test.png';

    # align='center' branch
    my $f1 = tmpnam() . '.pdf';
    my $b1 = PDF::Make::Builder->new(file_name => $f1);
    $b1->add_page(page_size => 'Letter');
    isa_ok(
        $b1->add_image(image => 't/fixtures/images/test.png', align => 'center', w => 100),
        'PDF::Make::Builder', 'add_image align=center');
    $b1->save;
    unlink $f1 if -f $f1;

    # x explicitly set (exercises x // content_x false-branch)
    my $f2 = tmpnam() . '.pdf';
    my $b2 = PDF::Make::Builder->new(file_name => $f2);
    $b2->add_page(page_size => 'Letter');
    isa_ok(
        $b2->add_image(image => 't/fixtures/images/test.png', x => 50, y => 500, w => 100, h => 80),
        'PDF::Make::Builder', 'add_image with explicit x/y/w/h');
    $b2->save;
    unlink $f2 if -f $f2;

    # no w (exercises w // page->width true-branch)
    my $f3 = tmpnam() . '.pdf';
    my $b3 = PDF::Make::Builder->new(file_name => $f3);
    $b3->add_page(page_size => 'Letter');
    isa_ok(
        $b3->add_image(image => 't/fixtures/images/test.png'),
        'PDF::Make::Builder', 'add_image no dimensions');
    $b3->save;
    unlink $f3 if -f $f3;

    # align='left' (non-center branch)
    my $f4 = tmpnam() . '.pdf';
    my $b4 = PDF::Make::Builder->new(file_name => $f4);
    $b4->add_page(page_size => 'Letter');
    isa_ok(
        $b4->add_image(image => 't/fixtures/images/test.png', align => 'left', w => 100),
        'PDF::Make::Builder', 'add_image align=left');
    $b4->save;
    unlink $f4 if -f $f4;

    # h-only (w derived from aspect ratio)
    my $f5 = tmpnam() . '.pdf';
    my $b5 = PDF::Make::Builder->new(file_name => $f5);
    $b5->add_page(page_size => 'Letter');
    isa_ok(
        $b5->add_image(image => 't/fixtures/images/test.png', h => 60),
        'PDF::Make::Builder', 'add_image h-only');
    $b5->save;
    unlink $f5 if -f $f5;
}

# ── Builder::Text pad/pad_end branch ─────────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    isa_ok(
        $b->add_text(text => 'Intro', pad => '.', pad_end => ' 42'),
        'PDF::Make::Builder', 'text with pad + pad_end');
    $b->save;
    unlink $f if -f $f;
}

# ── Builder::Text with indent and alignment variants ─────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    isa_ok($b->add_text(text => 'R', align => 'right'),
        'PDF::Make::Builder', 'text align=right');
    isa_ok($b->add_text(text => 'C', align => 'center'),
        'PDF::Make::Builder', 'text align=center');
    isa_ok($b->add_text(text => 'First para', indent => 4),
        'PDF::Make::Builder', 'text with indent');
    $b->save;
    unlink $f if -f $f;
}

# ── add_stamp visual and annotation modes ────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    isa_ok($b->add_stamp(text => 'DRAFT'),
        'PDF::Make::Builder', 'visual stamp default');
    isa_ok($b->add_stamp(text => 'APPROVED', y => 500),
        'PDF::Make::Builder', 'visual stamp with explicit y');
    isa_ok($b->add_stamp(rect => [100, 100, 200, 150], type => 'Confidential'),
        'PDF::Make::Builder', 'annotation stamp');

    my $b2 = PDF::Make::Builder->new(file_name => tmpnam() . '.pdf');
    eval { $b2->add_stamp(text => 'X') };
    like($@, qr/requires a current page/, 'stamp needs page');

    my $b3 = PDF::Make::Builder->new(file_name => tmpnam() . '.pdf');
    $b3->add_page;
    eval { $b3->add_stamp() };
    like($@, qr/requires rect or text/, 'stamp needs rect or text');
    $b->save;
    unlink $f if -f $f;
}

# ── add_note visual with explicit y; on_page target; out-of-range ─
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    $b->add_page(page_size => 'Letter');
    isa_ok($b->add_note(lines => ['L1', 'L2'], y => 400),
        'PDF::Make::Builder', 'add_note visual with explicit y');
    isa_ok($b->add_note(rect => [10, 10, 50, 30], text => 'hi', page => 0),
        'PDF::Make::Builder', 'add_note to specific page');
    eval { $b->add_note(rect => [0, 0, 10, 10], page => 99) };
    like($@, qr/out of range/, 'add_note on_page out of range dies');
    eval { $b->add_note() };
    like($@, qr/requires rect or lines/, 'add_note without rect/lines dies');
    $b->save;
    unlink $f if -f $f;
}

# ── set_color_space variants ─────────────────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    isa_ok($b->set_color_space('sRGB'),
        'PDF::Make::Builder', 'set_color_space sRGB');
    isa_ok($b->set_color_space('separation', name => 'Spot', c => 0.5),
        'PDF::Make::Builder', 'set_color_space separation');
    eval { $b->set_color_space('UnknownSpace') };
    like($@, qr/unknown color space/, 'set_color_space unknown dies');
    unlink $f if -f $f;
}

# ── add_field raw mode with x/y/w/h defaults ─────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter');
    isa_ok(
        $b->add_field(type => 'text', name => 'fld1', x => 50, default => 'hi'),
        'PDF::Make::Builder', 'add_field raw-mode defaults');
    isa_ok(
        $b->add_field(type => 'text', name => 'fld2',
                      rect => [50, 500, 200, 520], default_value => 'val'),
        'PDF::Make::Builder', 'add_field rect');
    eval { $b->add_field(type => 'text') };
    like($@, qr/requires name/, 'add_field needs name');
    eval { $b->add_field(name => 'x') };
    like($@, qr/requires type/, 'add_field needs type');
    eval { $b->add_field(type => 'nosuch', name => 'x') };
    like($@, qr/unknown field type/, 'add_field bad type dies');
    $b->save;
    unlink $f if -f $f;
}

done_testing;

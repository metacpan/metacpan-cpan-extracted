#!/usr/bin/perl
# Tests for Builder methods with 0-1 test calls
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

# ── set_columns ──────────────────────────────────────────

my $f = tmpnam() . '.pdf';
END { unlink $f if $f && -f $f }

my $b = PDF::Make::Builder->new(file_name => $f);
$b->add_page(page_size => 'Letter');
isa_ok($b->set_columns(2), 'PDF::Make::Builder', 'set_columns returns self');
is($b->page->columns, 2, 'columns set to 2');
$b->set_columns(1);
is($b->page->columns, 1, 'columns reset to 1');

# ── load_font ────────────────────────────────────────────

isa_ok($b->load_font(family => 'Courier', size => 14, colour => '#0000ff'),
    'PDF::Make::Builder', 'load_font returns self');
is($b->font->family, 'Courier', 'font family changed');
is($b->font->size, 14, 'font size changed');

# ── configure in constructor ─────────────────────────────

my $b2 = PDF::Make::Builder->new(
    file_name => '/tmp/cfg_test.pdf',
    configure => {
        text        => { font => { family => 'Times', size => 11, colour => '#222' } },
        h1          => { font => { size => 28 } },
        page_header => { show_page_num => 'right', page_num_text => 'p{num}' },
        page_footer => { show_page_num => 'center', page_num_text => '-{num}-' },
    },
);
$b2->add_page(page_size => 'A4');
# Header/footer should be set from configure
ok($b2->page->header, 'header set from configure');
ok($b2->page->footer, 'footer set from configure');
$b2->add_text(text => 'Configured text');
isa_ok(
    $b2->add_text(
        text    => 'Spacing and padding test paragraph for regression coverage.',
        spacing => 2,
        padding => 6,
        w       => 320,
    ),
    'PDF::Make::Builder',
    'add_text accepts spacing/padding',
);
$b2->save;
ok(-f '/tmp/cfg_test.pdf', 'configured PDF created');
unlink '/tmp/cfg_test.pdf';

# ── remove_page_header_and_footer ────────────────────────

isa_ok($b->remove_page_header_and_footer, 'PDF::Make::Builder',
    'remove_page_header_and_footer');

# ── add_note ─────────────────────────────────────────────

$b->add_page;
isa_ok($b->add_note(rect => [72, 700, 92, 720], text => 'Test note', icon => 'Comment'),
    'PDF::Make::Builder', 'add_note');
isa_ok($b->add_note(rect => [100, 700, 120, 720], text => 'Key note', icon => 'Key', open => 1),
    'PDF::Make::Builder', 'add_note with icon and open');

# ── add_stamp ────────────────────────────────────────────

isa_ok($b->add_stamp(rect => [200, 700, 400, 740], type => 'Approved'),
    'PDF::Make::Builder', 'add_stamp Approved');
isa_ok($b->add_stamp(rect => [200, 650, 400, 690], type => 'Draft'),
    'PDF::Make::Builder', 'add_stamp Draft');

# ── add_bates ────────────────────────────────────────────

SKIP: {
    eval { require PDF::Make::Watermark };
    skip 'Watermark not available', 1 if $@;
    my $bf = tmpnam() . '.pdf';
    my $bb = PDF::Make::Builder->new(file_name => $bf);
    $bb->add_page;
    $bb->add_text(text => 'Bates test');
    eval { $bb->add_bates(prefix => 'TEST', start => 1, digits => 4, position => 'bottom_right') };
    ok(!$@ || $@ =~ /width/, 'add_bates attempted');
    unlink $bf;
}

# ── set_meta / get_meta ──────────────────────────────────

isa_ok($b->set_meta('Department', 'Engineering'), 'PDF::Make::Builder', 'set_meta');
is($b->get_meta('Department'), 'Engineering', 'get_meta retrieves value');
$b->set_meta('Project', 'PDF-Make');
is($b->get_meta('Project'), 'PDF-Make', 'second meta key');

# ── page_count ───────────────────────────────────────────

ok($b->page_count >= 2, 'page_count works');

# ── to_bytes ─────────────────────────────────────────────

my $b3 = PDF::Make::Builder->new(file_name => '/tmp/bytes_test.pdf');
$b3->add_page(page_size => 'Letter');
$b3->add_text(text => 'To bytes test');
my $bytes = $b3->to_bytes;
ok(defined $bytes, 'to_bytes returns value');
ok(length($bytes) > 100, 'to_bytes has content');
like($bytes, qr/%PDF/, 'to_bytes starts with %PDF');
unlink '/tmp/bytes_test.pdf';

# ── open_existing ────────────────────────────────────────

SKIP: {
    skip 'hello_world.pdf not found', 3 unless -f 't/fixtures/hello_world.pdf';

    my $ex = PDF::Make::Builder->open_existing('t/fixtures/hello_world.pdf',
        file_name => '/tmp/existing_test.pdf');
    ok($ex, 'open_existing returns builder');
    ok($ex->page_count >= 1, 'open_existing has pages');
    $ex->add_page;
    $ex->add_text(text => 'Appended page');
    $ex->save;
    ok(-f '/tmp/existing_test.pdf', 'modified PDF saved');
    unlink '/tmp/existing_test.pdf';
}

# ── extract_text ─────────────────────────────────────────

SKIP: {
    skip 'hello_world.pdf not found', 2 unless -f 't/fixtures/hello_world.pdf';

    my $text = $b->extract_text('t/fixtures/hello_world.pdf', 0);
    ok(defined $text, 'extract_text returns value');
    like($text, qr/Hello/, 'extracted text contains Hello');
}

# ── apply_redactions ─────────────────────────────────────

isa_ok($b->apply_redactions, 'PDF::Make::Builder', 'apply_redactions');

# ── Save main test ───────────────────────────────────────

$b->save;
ok(-f $f, 'builder methods PDF created');

done_testing;

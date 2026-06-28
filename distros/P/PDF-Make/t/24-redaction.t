#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('PDF::Make::Document');
    use_ok('PDF::Make::Canvas');
    use_ok('PDF::Make::Redaction');
    use_ok('PDF::Make::Builder');
}

use PDF::Make::Page qw(:fonts);

# ── Setup document with content ──────────────────────────

my $doc = PDF::Make::Document->new;
$doc->title('Redaction Test');
$doc->author('Secret Author');
$doc->subject('Confidential');
my $page = $doc->add_page(612, 792);
$page->add_std14_font('F1', HELVETICA);

my $c = PDF::Make::Canvas->new;
$c->BT->Tf('F1', 12)->Tm(1,0,0,1, 72, 700)->Tj('SSN: 123-45-6789')->ET;
$c->BT->Tf('F1', 12)->Tm(1,0,0,1, 72, 680)->Tj('Phone: 555-0199')->ET;
$c->BT->Tf('F1', 12)->Tm(1,0,0,1, 72, 660)->Tj('Public info here')->ET;
$page->set_content($c->to_bytes);

# ── Mark redactions ──────────────────────────────────────

is(PDF::Make::Redaction->count($page), 0, 'no redactions initially');

# Redaction with rect array
PDF::Make::Redaction->mark($page,
    rect          => [72, 695, 300, 712],
    overlay_color => [0, 0, 0],
    overlay_text  => 'REDACTED',
);
is(PDF::Make::Redaction->count($page), 1, 'one redaction after first mark');

# Redaction with individual coordinates
PDF::Make::Redaction->mark($page,
    x0 => 72, y0 => 675, x1 => 250, y1 => 692,
    overlay_color => [1, 0, 0],
    overlay_text  => '[REMOVED]',
);
is(PDF::Make::Redaction->count($page), 2, 'two redactions after second mark');

# Redaction with no overlay (black fill only)
PDF::Make::Redaction->mark($page,
    rect => [72, 655, 200, 672],
);
is(PDF::Make::Redaction->count($page), 3, 'three redactions');

# Redaction with custom font size
PDF::Make::Redaction->mark($page,
    rect               => [300, 695, 500, 712],
    overlay_text       => 'CLASSIFIED',
    overlay_font_size  => 8,
);
is(PDF::Make::Redaction->count($page), 4, 'four redactions');

# ── Sanitize metadata ───────────────────────────────────

# Before sanitize
my $pre_bytes = $doc->to_bytes;
like($pre_bytes, qr/Secret Author/, 'author present before sanitize');

# Sanitize
PDF::Make::Redaction->sanitize($doc);

# ── Verify output ────────────────────────────────────────

# Need a fresh document since to_bytes finalizes
my $doc2 = PDF::Make::Document->new;
$doc2->title('Sanitize Test');
$doc2->author('Should Be Removed');
$doc2->subject('Also Removed');
$doc2->keywords('remove,these');
my $p2 = $doc2->add_page(612, 792);

PDF::Make::Redaction->sanitize($doc2);
my $bytes = $doc2->to_bytes;

unlike($bytes, qr/Should Be Removed/, 'author sanitized');
unlike($bytes, qr/Also Removed/, 'subject sanitized');
ok(length($bytes) > 100, 'PDF generated after sanitize');
like($bytes, qr/%PDF/, 'valid PDF header');
like($bytes, qr/%%EOF/, 'valid PDF trailer');

# ── Multi-page redaction ────────────────────────────────

my $doc3 = PDF::Make::Document->new;
my $p3a = $doc3->add_page(612, 792);
$p3a->add_std14_font('F1', HELVETICA);
my $c3a = PDF::Make::Canvas->new;
$c3a->BT->Tf('F1', 12)->Td(72, 700)->Tj('Page 1 secret')->ET;
$p3a->set_content($c3a->to_bytes);

my $p3b = $doc3->add_page(612, 792);
$p3b->add_std14_font('F1', HELVETICA);
my $c3b = PDF::Make::Canvas->new;
$c3b->BT->Tf('F1', 12)->Td(72, 700)->Tj('Page 2 secret')->ET;
$p3b->set_content($c3b->to_bytes);

PDF::Make::Redaction->mark($p3a, rect => [72, 695, 300, 712]);
PDF::Make::Redaction->mark($p3b, rect => [72, 695, 300, 712]);

is(PDF::Make::Redaction->count($p3a), 1, 'page 1 has 1 redaction');
is(PDF::Make::Redaction->count($p3b), 1, 'page 2 has 1 redaction');

my $bytes3 = $doc3->to_bytes;
ok(length($bytes3) > 200, 'multi-page redacted PDF has content');
like($bytes3, qr/%PDF/, 'multi-page PDF valid header');

# ── Apply via Builder ───────────────────────────────────

my $b = PDF::Make::Builder->new(file_name => '/tmp/redact_test.pdf');
$b->add_page(page_size => 'Letter');
$b->add_text(text => 'Sensitive data: 123-45-6789');
isa_ok($b->mark_redaction(page => 0, rect => [72, 700, 300, 720]),
    'PDF::Make::Builder', 'Builder mark_redaction returns self');
isa_ok($b->sanitize, 'PDF::Make::Builder', 'Builder sanitize returns self');

done_testing;

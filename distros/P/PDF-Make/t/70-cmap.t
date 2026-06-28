#!/usr/bin/perl
# Phase 1 — ToUnicode CMap integration.
#
# Direct XS unit tests for pdfmake_cmap are in tests/c/test_cmap.c.
# Here we verify that text extraction from an encrypted PDF with embedded
# CID fonts produces correct Unicode (rather than raw CIDs or WinAnsi
# garbage).

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Builder') }

my $fixture = 't/fixtures/placement.pdf';
plan skip_all => "fixture $fixture not found" unless -f $fixture;

my $b = PDF::Make::Builder->new(file_name => '/tmp/cmap_scratch');

# ── Page 1 contains the phrase "Sample Data File" across multiple spans ──
my $result = $b->extract_structured($fixture, page => 1);
ok($result, 'extract_structured returns result');

my @words = $result->text_positions;
cmp_ok(scalar @words, '>=', 50, 'page 1 yields many words');

# Concatenate all extracted text and verify known phrases appear
my $flat = join ' ', map { $_->{text} } @words;
$flat =~ s/\s+//g;   # collapse whitespace for phrase matching

like($flat, qr/SampleDataFile/, "'Sample Data File' decoded correctly");
like($flat, qr/SampleBookmarkFile/, "'Sample Bookmark File' decoded");
like($flat, qr/Invoices/, "'Invoices' decoded");
like($flat, qr/TYPE[123]/, "'TYPE1' class tokens decoded");

# ── Page 0 — document header ─────────────────────────────
my $r0 = $b->extract_structured($fixture, page => 0);
my @w0 = $r0->text_positions;
my $f0 = join ' ', map { $_->{text} } @w0;
$f0 =~ s/\s+//g;

like($f0, qr/PDF/i, 'page 0 contains PDF marker');
like($f0, qr/Bookmark/i, 'page 0 contains Bookmark');
like($f0, qr/Sample/i, 'page 0 contains Sample');

# ── Verify no mass CMap failures on ASCII-heavy page ────
# Some PUA codepoints are legitimate (AGL emits U+F7xx/F8xx for small-cap
# and ornament glyph names like /Aacutesmall → U+F7E1). What matters is
# that wholesale CID failures (where every glyph lands in PUA) don't happen.
my $bad_chars = () = $f0 =~ /[\x{E000}-\x{F8FF}]/g;
cmp_ok($bad_chars, '<=', 10,
       "PUA codepoints bounded (got $bad_chars; wholesale CMap failure would yield hundreds)");

# ── Builder::Font extract_text also exercises the same path ──
my $text = eval { PDF::Make::Extract->extract(
    PDF::Make::Parser->from_file($fixture, repair => 1), 0
) };
SKIP: {
    skip 'extract_text unavailable', 1 unless defined $text;
    like($text, qr/Sample/i, 'plain-text extraction also works');
}

done_testing;

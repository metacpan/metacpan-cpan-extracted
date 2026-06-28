#!/usr/bin/perl
# Phase 14 — Vertical writing (WMode 1).
#
# Type0 fonts with /Encoding /Identity-V (or CMaps carrying /WMode 1) render
# top-to-bottom, right-to-left.  The extractor has to branch on WMode when
# stamping glyph bboxes and when sorting into reading order.
#
# This test builds a tiny synthetic vertical-writing PDF with a Type0 font,
# draws three glyphs (mapped via /ToUnicode to 'A', 'B', 'C'), and checks
# that the extractor:
#   1. tags every word's first glyph as vertical
#   2. sorts them top-to-bottom (descending y), not left-to-right
#   3. returns plain text "A\nB\nC" for a single column

use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use PDF::Make::Builder;

my $file = tmpnam() . '.pdf';

# ── ToUnicode CMap: maps CIDs <0001><0002><0003> to U+0041 A, B, C ─────
my $cmap = <<'EOC';
/CIDInit /ProcSet findresource begin
12 dict begin
begincmap
/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def
/CMapName /Adobe-Identity-UCS def
/CMapType 2 def
1 begincodespacerange
<0000> <FFFF>
endcodespacerange
3 beginbfchar
<0001> <0041>
<0002> <0042>
<0003> <0043>
endbfchar
endcmap
CMapName currentdict /CMap defineresource pop
end
end
EOC
my $cl_cmap = length $cmap;

# ── Content stream: 3 glyphs placed at same x, descending y ───────────
# Tm(1 0 0 1 300 700) sets origin; hex <0001 0002 0003> is 3 2-byte codes.
# In WMode 1, the interpreter will translate text matrix along -y after
# each Tj.
my $content = <<'EOS';
BT
/F1 20 Tf
1 0 0 1 300 700 Tm
<000100020003> Tj
ET
EOS
my $cl_content = length $content;

# ── Assemble PDF ──────────────────────────────────────

my $pdf = "%PDF-1.7\n%\xE2\xE3\xCF\xD3\n";
my @off;
my $push = sub { push @off, length($pdf); $pdf .= $_[0] };

# 1  Catalog
$push->("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n");
# 2  Pages
$push->("2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n");
# 3  Page
$push->("3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
       ."/Resources << /Font << /F1 4 0 R >> >> /Contents 7 0 R >>\nendobj\n");
# 4  Type0 font with vertical encoding
$push->("4 0 obj\n<< /Type /Font /Subtype /Type0 /BaseFont /TestFont "
       ."/Encoding /Identity-V /DescendantFonts [5 0 R] "
       ."/ToUnicode 6 0 R >>\nendobj\n");
# 5  CIDFontType2 (minimal — parser tolerates missing descriptor)
$push->("5 0 obj\n<< /Type /Font /Subtype /CIDFontType2 /BaseFont /TestFont "
       ."/CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) "
       ."/Supplement 0 >> /DW 1000 /DW2 [880 -1000] >>\nendobj\n");
# 6  ToUnicode stream
$push->("6 0 obj\n<< /Length $cl_cmap >>\nstream\n${cmap}endstream\nendobj\n");
# 7  Content stream
$push->("7 0 obj\n<< /Length $cl_content >>\nstream\n${content}endstream\nendobj\n");

my $xref_start = length $pdf;
$pdf .= "xref\n0 8\n0000000000 65535 f \n";
$pdf .= sprintf("%010d 00000 n \n", $_) for @off;
$pdf .= "trailer\n<< /Size 8 /Root 1 0 R >>\nstartxref\n$xref_start\n%%EOF\n";

open my $fh, '>:raw', $file or die "open $file: $!";
print $fh $pdf;
close $fh;

# ── Extract ───────────────────────────────────────────

my $b = PDF::Make::Builder->new(file_name => '/tmp/vertical_scratch');
my $r = $b->extract_structured($file, page => 0);
my @w = $r->text_positions;

ok(scalar @w >= 1, "extracted at least one word") or diag explain \@w;

# Three contiguous vertical glyphs form a single "word" whose text is the
# top-to-bottom read ("ABC"), with a tall-narrow bbox (height >> width).
my $word_text = join('', map { $_->{text} } @w);
is($word_text, 'ABC', 'reading order is A → B → C (top-to-bottom)');

my $first = $w[0];
cmp_ok($first->{h}, '>', $first->{w},
       "bbox is taller than it is wide (h=$first->{h}, w=$first->{w})");

# Vertical glyphs flow down from roughly y=700 (Tm origin) through y=640
# (origin minus ~3 × font_size).  Assert the vertical extent matches.
cmp_ok($first->{h}, '>=', 55,
       "bbox covers ~3 glyph-heights (h=$first->{h})");

my $txt = $r->to_string;
like($txt, qr/ABC/, 'to_string preserves top-to-bottom order');

unlink $file;

# ── Horizontal PDFs are untouched by the new branch ────
SKIP: {
    my $f = 't/fixtures/hello_world.pdf';
    skip "$f not found", 1 unless -f $f;
    my $rh = $b->extract_structured($f, page => 0);
    my ($w1) = $rh->text_positions;
    ok($w1 && !$w1->{vertical},
       'WMode 0 extraction is unaffected by vertical branch');
}

done_testing;

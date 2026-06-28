#!/usr/bin/perl
# Phase 12 — Marked-content + StructTreeRoot.
#
# Tagged PDFs wrap drawing operations in BDC/EMC blocks carrying an /MCID,
# and declare a /StructTreeRoot in the catalog that maps MCIDs to semantic
# roles (H1, P, Figure, ...).  The text extractor now tracks the active
# MCID on each glyph and walks /StructTreeRoot so every word comes back
# stamped with its PDF role.
#
# This test builds a minimal tagged PDF by hand (no external dependency)
# and asserts the extractor returns mcid + tag on the expected words.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use PDF::Make::Builder;

# ── Build a tagged PDF by hand ──────────────────────────

my $file = tmpnam() . '.pdf';

# Content stream: H1 then two paragraphs, each wrapped in BDC/EMC with
# inline properties carrying /MCID.
my $content = <<'EOS';
/H1 << /MCID 0 >> BDC
BT /F1 18 Tf 72 720 Td (HEADING) Tj ET
EMC
/P << /MCID 1 >> BDC
BT /F1 12 Tf 72 690 Td (First paragraph) Tj ET
EMC
/P << /MCID 2 >> BDC
BT /F1 12 Tf 72 670 Td (Second paragraph) Tj ET
EMC
EOS
my $content_len = length $content;

# Hand-rolled PDF body. Keep object offsets as we go so the xref is exact.
my $pdf = "%PDF-1.7\n%\xE2\xE3\xCF\xD3\n";
my @off;

my $push = sub {
    my ($body) = @_;
    push @off, length($pdf);
    $pdf .= $body;
};

# 1: Catalog (references StructTreeRoot and MarkInfo)
$push->("1 0 obj\n<< /Type /Catalog /Pages 2 0 R /StructTreeRoot 6 0 R "
       ."/MarkInfo << /Marked true >> >>\nendobj\n");
# 2: Pages tree
$push->("2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n");
# 3: Page
$push->("3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
       ."/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R "
       ."/StructParents 0 >>\nendobj\n");
# 4: Font (Helvetica)
$push->("4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica "
       ."/Encoding /WinAnsiEncoding >>\nendobj\n");
# 5: Content stream (uncompressed so it's simple to inspect)
$push->("5 0 obj\n<< /Length $content_len >>\nstream\n${content}endstream\nendobj\n");
# 6: StructTreeRoot
$push->("6 0 obj\n<< /Type /StructTreeRoot /K [7 0 R 8 0 R 9 0 R] "
       ."/ParentTreeNextKey 1 >>\nendobj\n");
# 7: H1 struct elem (wraps MCID 0)
$push->("7 0 obj\n<< /Type /StructElem /S /H1 /P 6 0 R /Pg 3 0 R /K 0 >>\nendobj\n");
# 8: P struct elem (wraps MCID 1)
$push->("8 0 obj\n<< /Type /StructElem /S /P /P 6 0 R /Pg 3 0 R /K 1 >>\nendobj\n");
# 9: P struct elem (wraps MCID 2)
$push->("9 0 obj\n<< /Type /StructElem /S /P /P 6 0 R /Pg 3 0 R /K 2 >>\nendobj\n");

my $xref_start = length $pdf;
$pdf .= "xref\n0 10\n0000000000 65535 f \n";
$pdf .= sprintf("%010d 00000 n \n", $_) for @off;
$pdf .= "trailer\n<< /Size 10 /Root 1 0 R >>\nstartxref\n$xref_start\n%%EOF\n";

open my $fh, '>:raw', $file or die "open $file: $!";
print $fh $pdf;
close $fh;

# ── Extract and verify ─────────────────────────────────

my $b = PDF::Make::Builder->new(file_name => '/tmp/tagged_scratch');
my $r = $b->extract_structured($file, page => 0);
my @w = $r->text_positions;

ok(scalar @w, 'got words from tagged PDF');

my ($head) = grep { $_->{text} =~ /HEADING/ } @w;
my ($p1)   = grep { $_->{text} =~ /First/   } @w;
my ($p2)   = grep { $_->{text} =~ /Second/  } @w;

ok($head, 'HEADING word present');
ok($p1,   'First paragraph word present');
ok($p2,   'Second paragraph word present');

# MCIDs flow through from the content stream
is($head->{mcid}, 0, 'HEADING carries MCID 0');
is($p1->{mcid},   1, 'First paragraph carries MCID 1');
is($p2->{mcid},   2, 'Second paragraph carries MCID 2');

# StructTreeRoot walk maps MCIDs to structure roles
is($head->{tag}, 'H1', 'HEADING tagged as H1 via StructTreeRoot');
is($p1->{tag},   'P',  'First paragraph tagged as P');
is($p2->{tag},   'P',  'Second paragraph tagged as P');

# Same data should also be reachable through the Word accessors
my ($head_w) = grep { $_->text =~ /HEADING/ } $r->words;
ok($head_w, 'Word object for HEADING');
is($head_w->mcid, 0,  'Word->mcid accessor');
is($head_w->tag, 'H1', 'Word->tag accessor');

# ── Untagged PDFs leave mcid/tag undef ─────────────────
SKIP: {
    my $f = 't/fixtures/hello_world.pdf';
    skip "$f not found", 2 unless -f $f;

    my $r2 = $b->extract_structured($f, page => 0);
    my @w2 = $r2->text_positions;
    ok(scalar @w2, 'extracted words from untagged PDF');
    my $any_tagged = grep { defined $_->{mcid} || defined $_->{tag} } @w2;
    is($any_tagged, 0, 'untagged PDF produces no mcid/tag fields');
}

unlink $file;

done_testing;

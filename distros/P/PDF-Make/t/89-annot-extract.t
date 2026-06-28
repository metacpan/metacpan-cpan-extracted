#!/usr/bin/perl
# Phase 13 — Annotation + form-field text extraction.
#
# Page content streams don't carry sticky-note text or filled form values.
# This test hand-builds a minimal PDF with a Text annotation, a FreeText
# annotation, and a Tx (text) form field, then checks that all three come
# back through $builder->extract_annotations.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use PDF::Make::Builder;

my $file = tmpnam() . '.pdf';

# ── Build PDF by hand ───────────────────────────────────

my $content = "BT /F1 12 Tf 72 720 Td (Body text) Tj ET\n";
my $cl = length $content;

my $pdf = "%PDF-1.7\n%\xE2\xE3\xCF\xD3\n";
my @off;
my $push = sub { push @off, length($pdf); $pdf .= $_[0] };

# 1 Catalog (references AcroForm)
$push->("1 0 obj\n<< /Type /Catalog /Pages 2 0 R /AcroForm 10 0 R >>\nendobj\n");
# 2 Pages
$push->("2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n");
# 3 Page (Annots references sticky + free-text + widget)
$push->("3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
       ."/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R "
       ."/Annots [6 0 R 7 0 R 11 0 R] >>\nendobj\n");
# 4 Font
$push->("4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica "
       ."/Encoding /WinAnsiEncoding >>\nendobj\n");
# 5 Content
$push->("5 0 obj\n<< /Length $cl >>\nstream\n${content}endstream\nendobj\n");
# 6 Sticky note annotation (Text)
$push->("6 0 obj\n<< /Type /Annot /Subtype /Text /Rect [100 700 120 720] "
       ."/Contents (This is a sticky note) /T (Alice) "
       ."/Subj (Question) >>\nendobj\n");
# 7 FreeText annotation
$push->("7 0 obj\n<< /Type /Annot /Subtype /FreeText /Rect [200 650 400 700] "
       ."/Contents (Free-floating comment) /T (Bob) >>\nendobj\n");

# 10 AcroForm dict referencing fields array (root field is 11)
$push->("10 0 obj\n<< /Fields [11 0 R] >>\nendobj\n");

# 11 Widget + terminal field combined (a common AcroForm shape)
$push->("11 0 obj\n<< /Type /Annot /Subtype /Widget /FT /Tx /P 3 0 R "
       ."/T (email) /V (alice\@example.com) /TU (Your email address) "
       ."/Rect [72 560 300 580] >>\nendobj\n");

my $xref_start = length $pdf;
# Object numbers: 1..7 plus 10,11 — xref must cover 0..11 contiguously.
$pdf .= "xref\n0 12\n0000000000 65535 f \n";
# Emit entries 1..7, 8..9 as free, 10..11
for my $n (1..7) {
    $pdf .= sprintf("%010d 00000 n \n", $off[$n - 1]);
}
# 8 and 9 are unused → free entries
$pdf .= "0000000000 65535 f \n";
$pdf .= "0000000000 65535 f \n";
$pdf .= sprintf("%010d 00000 n \n", $off[7]);    # obj 10 = index 7 (pushed 8th)
$pdf .= sprintf("%010d 00000 n \n", $off[8]);    # obj 11 = index 8

$pdf .= "trailer\n<< /Size 12 /Root 1 0 R >>\nstartxref\n$xref_start\n%%EOF\n";

open my $fh, '>:raw', $file or die "open $file: $!";
print $fh $pdf;
close $fh;

# ── Extract and check ──────────────────────────────────

my $b = PDF::Make::Builder->new(file_name => '/tmp/annot_scratch');
my @ann = $b->extract_annotations($file);

ok(scalar @ann >= 3, "at least 3 annotation records (got @{[scalar @ann]})")
    or diag explain \@ann;

my ($note) = grep { ($_->{kind}||'') eq 'Text' } @ann;
my ($ft)   = grep { ($_->{kind}||'') eq 'FreeText' } @ann;
my ($fld)  = grep { ($_->{kind}||'') eq 'FormField' } @ann;

ok($note, 'sticky-note annotation present');
is($note->{text},   'This is a sticky note', 'sticky /Contents');
is($note->{author}, 'Alice',                 'sticky /T (author)');
is($note->{subject},'Question',              'sticky /Subj');
is($note->{page},   0,                       'sticky page index');
is_deeply($note->{rect}, [100,700,120,720],  'sticky /Rect');

ok($ft, 'free-text annotation present');
is($ft->{text}, 'Free-floating comment', 'free-text contents');

ok($fld, 'form field value present');
is($fld->{field_name}, 'email',             'form /T field name');
is($fld->{text},       'alice@example.com', 'form /V value');
is($fld->{subject},    'Your email address','form /TU tooltip surfaces as subject');

unlink $file;

# ── PDFs with no annots/forms → empty list ──────────────
SKIP: {
    my $f = 't/fixtures/hello_world.pdf';
    skip "$f not found", 1 unless -f $f;
    my @none = $b->extract_annotations($f);
    is(scalar @none, 0, 'annotation-free PDF yields empty list');
}

done_testing;

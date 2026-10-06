#!/usr/bin/perl
# TrueType embedding.
#
# load_ttf used to croak "failed to write font to document" for every font on
# every platform: pdfmake_font_write was a stub returning a null reference,
# nothing set a TTF's /BaseFont, and pdfmake_page_add_font refuses any name
# that is not one of the Standard 14, so the page could not have referenced
# the font even if it had been written.
#
# The font here is built in-process rather than taken from the system, so the
# test runs everywhere instead of skipping on the smokers that have no fonts
# installed - and the glyph set is known, which is what lets the subset
# assertions below be exact.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

# ── A minimal but real TrueType font ────────────────────
#
# Five glyphs: .notdef plus A B C D, at four different advances so a width
# that came from the wrong glyph is visible in /W.

use constant {
    UPEM        => 1000,
    NUM_GLYPHS  => 5,
};

my @ADVANCE = (500, 600, 700, 800, 900);   # by glyph id

sub be16 { return pack 'n', ($_[0] & 0xFFFF) }
sub be32 { return pack 'N', $_[0] }
sub s16  { return pack 'n', ($_[0] < 0 ? $_[0] + 65536 : $_[0]) }

# One square contour, so glyf is real data the subsetter has to copy.
sub simple_glyph {
    my ($w, $h) = @_;
    return be16(1)                              # numberOfContours
         . s16(0) . s16(0) . s16($w) . s16($h)  # bbox
         . be16(3)                              # endPtsOfContours[0]
         . be16(0)                              # instructionLength
         . pack('C4', 0x01, 0x01, 0x01, 0x01)   # flags: on-curve, int16 deltas
         . s16(0) . s16($w) . s16(0) . s16(-$w) # x deltas
         . s16(0) . s16(0) . s16($h) . s16(0);  # y deltas
}

sub build_ttf {
    my ($psname) = @_;

    # glyf + loca. Glyph 0 (.notdef) is empty; A-D are squares.
    my @glyphs = ('', map { simple_glyph(400 + 50 * $_, 600 + 20 * $_) } 1 .. 4);
    my $glyf = '';
    my @offsets;
    for my $g (@glyphs) {
        push @offsets, length $glyf;
        $glyf .= $g;
    }
    push @offsets, length $glyf;
    # Short loca stores offset/2, so every glyph must start on an even byte.
    die 'glyf must be 2-byte aligned' if grep { $_ % 2 } @offsets;
    my $loca = join '', map { be16($_ / 2) } @offsets;

    my $head = be32(0x00010000) . be32(0)       # version, fontRevision
             . be32(0) . be32(0x5F0F3CF5)       # checkSumAdjustment, magic
             . be16(0) . be16(UPEM)             # flags, unitsPerEm
             . be32(0) . be32(0)                # created
             . be32(0) . be32(0)                # modified
             . s16(0) . s16(0) . s16(650) . s16(680)   # xMin yMin xMax yMax
             . be16(0) . be16(8) . be16(2)      # macStyle, lowestRec, dirHint
             . be16(0) . be16(0);               # indexToLocFormat=short, fmt
    die 'head must be 54 bytes' unless length($head) == 54;

    my $hhea = be32(0x00010000)
             . s16(800) . s16(-200) . s16(0)    # ascender descender lineGap
             . be16(900) . s16(0) . s16(0) . s16(650)
             . s16(1) . s16(0) . s16(0)
             . s16(0) . s16(0) . s16(0) . s16(0)
             . s16(0) . be16(NUM_GLYPHS);       # metricDataFormat, numHMetrics
    die 'hhea must be 36 bytes' unless length($hhea) == 36;

    my $maxp = be32(0x00010000) . be16(NUM_GLYPHS) . (be16(0) x 13);
    my $hmtx = join '', map { be16($ADVANCE[$_]) . s16(0) } 0 .. NUM_GLYPHS - 1;

    # cmap format 4: one segment for U+0041..U+0044, plus the required
    # 0xFFFF terminator.
    my $fmt4 = be16(4) . be16(32) . be16(0)
             . be16(4) . be16(4) . be16(1) . be16(0)   # segCountX2 and friends
             . be16(0x0044) . be16(0xFFFF)             # endCode
             . be16(0)                                 # reservedPad
             . be16(0x0041) . be16(0xFFFF)             # startCode
             . be16(1 - 0x41) . be16(1)                # idDelta
             . be16(0) . be16(0);                      # idRangeOffset
    die 'cmap subtable must be 32 bytes' unless length($fmt4) == 32;
    my $cmap = be16(0) . be16(1) . be16(3) . be16(1) . be32(12) . $fmt4;

    # name: just nameID 6, the PostScript name, UTF-16BE on platform 3.
    my $str = join '', map { be16(ord $_) } split //, $psname;
    my $name = be16(0) . be16(1) . be16(6 + 12)
             . be16(3) . be16(1) . be16(0x409) . be16(6)
             . be16(length $str) . be16(0)
             . $str;

    my $post = be32(0x00030000) . (be32(0) x 7);

    my @tables = (
        [ 'cmap', $cmap ], [ 'glyf', $glyf ], [ 'head', $head ],
        [ 'hhea', $hhea ], [ 'hmtx', $hmtx ], [ 'loca', $loca ],
        [ 'maxp', $maxp ], [ 'name', $name ], [ 'post', $post ],
    );

    my $n = scalar @tables;
    my $entry_sel = 0;
    $entry_sel++ while (1 << ($entry_sel + 1)) <= $n;
    my $search = (1 << $entry_sel) * 16;

    my $dir = be32(0x00010000) . be16($n) . be16($search)
            . be16($entry_sel) . be16($n * 16 - $search);

    my $offset = 12 + $n * 16;
    my $body = '';
    for my $t (@tables) {
        my ($tag, $data) = @$t;
        $dir .= $tag . be32(0) . be32($offset + length $body)
              . be32(length $data);
        $body .= $data;
        $body .= "\0" x (-length($body) % 4);   # 4-byte align the next table
    }

    return $dir . $body;
}

my $ttf_bytes = build_ttf('TestFontPM');
my $ttf_path  = tmpnam() . '.ttf';
open my $tfh, '>:raw', $ttf_path or die "cannot write $ttf_path: $!";
print $tfh $ttf_bytes;
close $tfh;
END { unlink $ttf_path if defined $ttf_path }

ok(length($ttf_bytes) > 200, 'built a TrueType font to embed');

# ── The font parses, and carries its own name ───────────

{
    my $f = PDF::Make::Font->from_file($ttf_path);
    ok($f, 'from_file parses it');
    is($f->base_font, 'TestFontPM', 'base_font comes from the name table');
    # A was built with advance 600/1000 em.
    cmp_ok(abs($f->string_width('A', 10) - 6), '<', 0.001,
           'string_width uses the real hmtx advance');
}

# ── load_ttf, and a page that draws with it ─────────────

sub build_doc {
    my (%args) = @_;
    my $file = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $file);
    $b->add_page(page_size => 'Letter')
      ->load_ttf($ttf_path, name => 'Embedded');
    $b->add_text(text => 'Plain line.');
    $b->add_text(text => $args{text} // 'ABCD',
                 font => { family => 'Embedded', size => 20 });
    $b->save;

    open my $fh, '<:raw', $file or die "cannot read $file: $!";
    my $bytes = do { local $/; <$fh> };
    close $fh;
    return ($file, $bytes);
}

sub obj_body {
    my ($bytes, $num) = @_;
    my ($body) = $bytes =~ m{(?:^|[\r\n])\Q$num\E\s+0\s+obj(.*?)endobj}s;
    return defined $body ? $body : '';
}

my ($file, $bytes) = build_doc();

my ($type0_num) = $bytes =~ m{/F_Embedded\s+(\d+)\s+0\s+R};
ok($type0_num, 'the page resources name the embedded font');

my $type0 = obj_body($bytes, $type0_num);
like($type0, qr{/Subtype\s*/Type0},        'it is a composite font');
like($type0, qr{/Encoding\s*/Identity-H},  'Identity-H encoding');
like($type0, qr{/ToUnicode\s+\d+\s+0\s+R}, 'carries a ToUnicode CMap');
like($type0, qr{/BaseFont\s*/[A-Z]{6}\+TestFontPM},
     'BaseFont has a six-letter subset tag');

my ($cid_num) = $type0 =~ m{/DescendantFonts\s*\[\s*(\d+)\s+0\s+R};
ok($cid_num, 'has a descendant font');

my $cid = obj_body($bytes, $cid_num);
like($cid, qr{/Subtype\s*/CIDFontType2}, 'descendant is CIDFontType2');
like($cid, qr{/CIDToGIDMap\s+\d+\s+0\s+R},
     'CIDToGIDMap is a stream, not /Identity');

# /Identity here would be a silent wrong-glyph bug: the subsetter renumbers
# glyphs, so a CID that is a glyph id in the original font is a different
# glyph in the embedded one.
unlike($cid, qr{/CIDToGIDMap\s*/Identity}, 'CIDToGIDMap is not /Identity');

my ($descr_num) = $cid =~ m{/FontDescriptor\s+(\d+)\s+0\s+R};
ok($descr_num, 'descendant has a FontDescriptor');
my $descr = obj_body($bytes, $descr_num);
like($descr, qr{/FontFile2\s+\d+\s+0\s+R}, 'the font program is embedded');

# ── Widths come from the font, per glyph ────────────────

my ($w_array) = $cid =~ m{/W\s*\[(.*?)\]\s*/CIDToGIDMap}s;
ok(defined $w_array, 'the descendant carries a /W array');

SKIP: {
    skip 'no /W array', 1 unless defined $w_array;
    my @nums = $w_array =~ /(\d+)/g;
    my %widths = map { $_ => 1 } grep { $_ >= 500 && $_ <= 900 } @nums;
    # 'ABCD' are gids 1-4 with advances 600 700 800 900.
    ok($widths{600} && $widths{700} && $widths{800} && $widths{900},
       'every drawn glyph contributes its own advance');
}

# ── The text is shown as glyph ids, not characters ──────

like($bytes, qr{<[0-9A-F]+>\s*Tj},
     'composite text is shown as a hex string of glyph ids');

# ── Only the glyphs actually drawn are embedded ─────────

{
    my (undef, $one) = build_doc(text => 'A');
    my ($c1) = $one =~ m{/F_Embedded\s+(\d+)\s+0\s+R};
    my $cid1 = obj_body($one, (obj_body($one, $c1) =~ m{/DescendantFonts\s*\[\s*(\d+)})[0]);
    my ($w1) = $cid1 =~ m{/W\s*\[(.*?)\]\s*/CIDToGIDMap}s;
    my @n1 = grep { $_ >= 500 && $_ <= 900 } ($w1 =~ /(\d+)/g);
    # .notdef (500) plus A (600) only — not B, C or D.
    ok(!grep({ $_ == 900 } @n1), 'a glyph that was never drawn is not embedded');
}

# ── Round-trip ──────────────────────────────────────────

{
    # scalar(): tmpnam() in list context yields a handle AND a name.
    my $b = PDF::Make::Builder->new(file_name => scalar tmpnam());
    my $r = $b->extract_structured($file, page => 0);
    my $text = join ' ', map { $_->{text} } $r->text_positions;
    like($text, qr/ABCD/, 'embedded text extracts back through ToUnicode');
    like($text, qr/Plain line\./, 'the Standard 14 text is still readable');
}

# ── The family reaches every path a font can travel ─────
#
# A Builder::Font is cloned, field by field, in five places. A clone that
# drops the registry silently falls back to treating 'Embedded' as an unknown
# Standard 14 family, so each of these would die or draw the wrong font.

{
    my $file2 = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $file2);
    $b->add_page(page_size => 'Letter')
      ->load_ttf($ttf_path, name => 'Embedded');

    # Styled runs (Text::_resolve_runs)
    $b->add_text(text => 'ABCD', runs => [
        { text => 'AB', family => 'Embedded' },
        { text => 'CD' },
    ]);

    # A header drawn through HeaderFooterContext::_font
    $b->add_page_header(text => 'ABCD', font => { family => 'Embedded' });

    # A table cell, plain and with runs (Layout::Cell)
    my $row = $b->layout->row(height => 80);
    $row->cell(weight => 1)->text('ABCD', family => 'Embedded');
    $row->cell(weight => 1)->runs([ { text => 'ABCD', family => 'Embedded' } ]);

    ok(eval { $b->save; 1 }, 'runs, cells and headers accept an embedded family')
        or diag $@;

    open my $fh2, '<:raw', $file2 or die "cannot read $file2: $!";
    my $b2 = do { local $/; <$fh2> };
    close $fh2;
    like($b2, qr{/F_Embedded\s+\d+\s+0\s+R},
         'the embedded font reached the page through those paths');
    unlink $file2;
}

unlink $file;

done_testing;

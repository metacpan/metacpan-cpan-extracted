#!/usr/bin/perl
# Tests for Font.pm Perl wrapper methods
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Font') }

# ── is_standard14 / is_truetype ──────────────────────────

my $helv = PDF::Make::Font->standard14('Helvetica');
ok($helv->is_standard14, 'Helvetica is standard14');
ok(!$helv->is_truetype, 'Helvetica is not truetype');

my $times = PDF::Make::Font->standard14('Times-Roman');
ok($times->is_standard14, 'Times is standard14');

# ── Font new() constructor ───────────────────────────────

SKIP: {
    my $new_font = eval { PDF::Make::Font->new };
    skip 'Font::new not available or requires args', 2 unless $new_font;
    ok($new_font, 'Font::new works');
    ok(defined $new_font->type, 'new font has type');
}

# ── lookup (Standard 14 width table) ────────────────────

for my $name ('Helvetica', 'Times-Roman', 'Courier') {
    my $font = PDF::Make::Font->standard14($name);
    my $m = $font->metrics;
    ok(ref $m eq 'HASH', "$name metrics");
    ok(exists $m->{ascent}, "$name has ascent");
    ok(exists $m->{descent}, "$name has descent");
    ok(exists $m->{stem_v}, "$name has stem_v");

    # Width of common characters
    for my $cp (65, 97, 48, 32) {  # A, a, 0, space
        my $adv = $font->advance($cp, 12.0);
        ok($adv > 0, "$name advance($cp) > 0");
    }
}

# ── String width with various inputs ─────────────────────

my $f = PDF::Make::Font->standard14('Helvetica');

# Normal text
my $w1 = $f->string_width('Hello', 10.0);
ok($w1 > 0, 'string_width Hello > 0');

# Spaces
my $w2 = $f->string_width('   ', 10.0);
ok($w2 > 0, 'string_width spaces > 0');

# Numbers
my $w3 = $f->string_width('12345', 10.0);
ok($w3 > 0, 'string_width digits > 0');

# Punctuation
my $w4 = $f->string_width('...', 10.0);
ok($w4 > 0, 'string_width punctuation > 0');

# Long string
my $w5 = $f->string_width('A' x 100, 12.0);
ok($w5 > 500, 'long string has large width');

# Size 0
my $w0 = $f->string_width('Test', 0.0);
cmp_ok($w0, '==', 0, 'size 0 = width 0');

# ── Metrics bbox ─────────────────────────────────────────

my $m = $f->metrics;
my $bbox = $m->{bbox};
is(ref $bbox, 'ARRAY', 'bbox is array');
is(scalar @$bbox, 4, 'bbox has 4 elements');
ok($bbox->[2] > $bbox->[0], 'bbox urx > llx');
ok($bbox->[3] > $bbox->[1], 'bbox ury > lly');

done_testing;

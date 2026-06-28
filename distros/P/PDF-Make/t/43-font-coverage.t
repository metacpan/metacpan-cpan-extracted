#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Font') }

# ── All 14 standard fonts ───────────────────────────────

my @fonts = (
    'Helvetica', 'Helvetica-Bold', 'Helvetica-Oblique', 'Helvetica-BoldOblique',
    'Times-Roman', 'Times-Bold', 'Times-Italic', 'Times-BoldItalic',
    'Courier', 'Courier-Bold', 'Courier-Oblique', 'Courier-BoldOblique',
    'Symbol', 'ZapfDingbats',
);

for my $name (@fonts) {
    my $font = PDF::Make::Font->standard14($name);
    ok($font, "standard14($name) created");
    is($font->base_font, $name, "$name base_font correct");
    ok(defined $font->type, "$name type defined");
}

# ── Metrics ──────────────────────────────────────────────

my $helv = PDF::Make::Font->standard14('Helvetica');
my $m = $helv->metrics;
ok(ref $m eq 'HASH', 'metrics returns hashref');
ok($m->{ascent} > 0, 'ascent > 0');
ok($m->{descent} < 0, 'descent < 0');
ok(defined $m->{cap_height}, 'cap_height defined');
ok(defined $m->{x_height}, 'x_height defined');
ok(ref $m->{bbox} eq 'ARRAY', 'bbox is arrayref');
is(scalar @{$m->{bbox}}, 4, 'bbox has 4 elements');
ok(defined $m->{stem_v}, 'stem_v defined');
ok(defined $m->{italic_angle}, 'italic_angle defined');
ok(defined $m->{flags}, 'flags defined');

# ── Advance ──────────────────────────────────────────────

my $adv_H = $helv->advance(72, 12.0);  # 'H' = codepoint 72
ok($adv_H > 0, "advance('H', 12) > 0: $adv_H");

my $adv_i = $helv->advance(105, 12.0); # 'i' = codepoint 105
ok($adv_i > 0, "advance('i', 12) > 0: $adv_i");
ok($adv_H > $adv_i, "'H' wider than 'i' in Helvetica");

# Courier should be monospace
my $cour = PDF::Make::Font->standard14('Courier');
my $cour_H = $cour->advance(72, 12.0);
my $cour_i = $cour->advance(105, 12.0);
cmp_ok(abs($cour_H - $cour_i), '<', 0.01, 'Courier is monospace');

# ── String width ─────────────────────────────────────────

my $w1 = $helv->string_width('Hello', 12.0);
ok($w1 > 0, "string_width('Hello', 12) > 0: $w1");

my $w2 = $helv->string_width('Hello World', 12.0);
ok($w2 > $w1, "'Hello World' wider than 'Hello'");

my $w_space = $helv->string_width(' ', 12.0);
ok($w_space > 0, 'space has width');

# Empty string
my $w_empty = $helv->string_width('', 12.0);
cmp_ok($w_empty, '==', 0, 'empty string width is 0');

# ── Different sizes ──────────────────────────────────────

my $w_12 = $helv->string_width('Test', 12.0);
my $w_24 = $helv->string_width('Test', 24.0);
cmp_ok(abs($w_24 - $w_12 * 2), '<', 0.1, 'width scales with size');

# ── Font type ────────────────────────────────────────────

is($helv->type, 0, 'Helvetica type is 0 (Type1)');

done_testing;

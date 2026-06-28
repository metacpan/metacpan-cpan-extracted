#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('PDF::Make::Font');
use_ok('PDF::Make::Font::Std14');

# Get constants
my $TYPE_TYPE1 = PDF::Make::Font::TYPE_TYPE1();

# Test Standard 14 constants (called as functions, not methods)
is(PDF::Make::Font::Std14::HELVETICA(), 0, 'HELVETICA constant');
is(PDF::Make::Font::Std14::TIMES_ROMAN(), 4, 'TIMES_ROMAN constant');
is(PDF::Make::Font::Std14::COURIER(), 8, 'COURIER constant');
is(PDF::Make::Font::Std14::SYMBOL(), 12, 'SYMBOL constant');
is(PDF::Make::Font::Std14::ZAPFDINGBATS(), 13, 'ZAPFDINGBATS constant');

# Test lookup (method call)
is(PDF::Make::Font::Std14->lookup('Helvetica'), 0, 'lookup Helvetica');
is(PDF::Make::Font::Std14->lookup('Times-Roman'), 4, 'lookup Times-Roman');
is(PDF::Make::Font::Std14->lookup('Courier-Bold'), 9, 'lookup Courier-Bold');
is(PDF::Make::Font::Std14->lookup('UnknownFont'), -1, 'lookup unknown returns -1');

# Test width lookup (method call)
my $width_A = PDF::Make::Font::Std14->width(
    PDF::Make::Font::Std14::HELVETICA(), 
    ord('A')
);
is($width_A, 667, 'Helvetica A width is 667');

my $width_space = PDF::Make::Font::Std14->width(
    PDF::Make::Font::Std14::HELVETICA(), 
    ord(' ')
);
is($width_space, 278, 'Helvetica space width is 278');

# Test font creation
my $font = PDF::Make::Font->standard14('Helvetica');
ok($font, 'created Helvetica font');
is($font->base_font, 'Helvetica', 'base_font accessor');
is($font->type, $TYPE_TYPE1, 'type is TYPE1');
ok($font->is_standard14, 'is_standard14 returns true');
ok(!$font->is_truetype, 'is_truetype returns false');
is($font->std14_id, PDF::Make::Font::Std14::HELVETICA(), 'std14_id');

# Test font metrics
my $metrics = $font->metrics;
ok(ref $metrics eq 'HASH', 'metrics returns hashref');
ok(exists $metrics->{ascent}, 'metrics has ascent');
ok(exists $metrics->{descent}, 'metrics has descent');
ok(exists $metrics->{cap_height}, 'metrics has cap_height');
ok(exists $metrics->{x_height}, 'metrics has x_height');
ok(exists $metrics->{bbox}, 'metrics has bbox');
is(ref $metrics->{bbox}, 'ARRAY', 'bbox is array');
is(scalar @{$metrics->{bbox}}, 4, 'bbox has 4 elements');

# Test glyph advance
my $advance = $font->advance(ord('A'), 12);
ok($advance > 0, 'advance returns positive value');
# 667/1000 * 12 = 8.004
cmp_ok(abs($advance - 8.004), '<', 0.001, 'advance for A at 12pt');

# Test string width
my $width = $font->string_width('Hello', 12);
ok($width > 0, 'string_width returns positive value');

# Test UTF-8 string width
my $utf8_width = $font->string_width('Héllo', 12);
ok($utf8_width > 0, 'UTF-8 string_width works');

# Test encode_utf8
my $encoded = $font->encode_utf8('Hello');
ok(defined $encoded, 'encode_utf8 returns data');
ok(length($encoded) > 0, 'encoded data has length');

# Test other Standard 14 fonts
no warnings 'once';  # STD14_NAMES is exported from PDF::Make::Font
my @std14_names = @PDF::Make::Font::STD14_NAMES;
use warnings 'once';
for my $name (@std14_names) {
    my $f = PDF::Make::Font->standard14($name);
    ok($f, "created $name font");
    is($f->base_font, $name, "$name base_font");
}

# Test new() with standard14 option
my $font2 = PDF::Make::Font->new(standard14 => 'Times-Roman');
ok($font2, 'new() with standard14 option');
is($font2->base_font, 'Times-Roman', 'new() created correct font');

# Test invalid font name
eval { PDF::Make::Font->standard14('InvalidFont') };
ok($@, 'invalid font name throws error');
like($@, qr/unknown/, 'error mentions unknown');

done_testing();

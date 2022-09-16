#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 2;
my $test_count = 2;

use PDF::Builder;

my @possible_locations = (
    '/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/var/lib/defoma/gs.d/dirs/fonts/DejaVuSans.ttf',
    'C:/Windows/fonts/DejaVuSans.ttf',
);

my ($font_file) = grep { -f && -r } @possible_locations;

SKIP: {
    skip "Skipping TTF tests... DejaVu Sans font not found", $test_count
        unless $font_file;

    my $pdf = PDF::Builder->new();
    my $font = $pdf->font($font_file); # originally ttfont()

    # Do something with the font to see if it appears to have opened
    # properly.
    ok($font->glyphNum() > 0,
       q{Able to read a count of glyphs (>0) from a TrueType font});

    like($font->{'Name'}->val(), qr/^De/,
	 q{Font has the expected name});
}

1;

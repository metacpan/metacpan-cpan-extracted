#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 2;
my $test_count = 2;

use PDF::Builder;

#my $pfb_file = '/usr/share/fonts/type1/gsfonts/a010013l.pfb';
#my $pfm_file = '/usr/share/fonts/type1/gsfonts/a010013l.pfm';
my $pfb_file = 'C:/Program Files (x86)/MikTex 2.9/fonts/type1/urw/bookman/ubkd8a.pfb';
my $pfm_file = 'C:/Program Files (x86)/MikTex 2.9/fonts/type1/urw/bookman/ubkd8a.pfm';

SKIP: {
    skip "Skipping Type1 tests... URW Gothic L Book font not found", $test_count
        unless (-f $pfb_file and -r $pfb_file and -f $pfm_file and -r $pfm_file);

    my $pdf = PDF::Builder->new();
    my $font = $pdf->psfont($pfb_file, -pfmfile => $pfm_file);

    # Do something with the font to see if it appears to have opened
    # properly.
    ok($font->glyphNum() > 0,
       q{Able to read a count of glyphs (>0) from a Type1 font});

    like($font->{'Name'}->val(), qr/^Ur/,
	 q{Font has the expected name});

}

1;

#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 2;
my $test_count = 2;

use PDF::Builder;

my (@pfb_list, @pfm_list);
my ($pfb_file, $pfm_file);

my $OSname = $^O;

# expecting a matching pfb and pfm set. if you have .pfa and/or .afm|.xfm,
# something will have to be done about that
if ($OSname eq 'MSWin32') {
    # Windows systems (MikTex installation assumed, as Windows doesn't come
    # with any Type1 fonts preinstalled). new and older MiKTeX paths.
    push @pfb_list, 'C:/Program Files/MikTex 2.9/fonts/type1/urw/bookman/ubkd8a.pfb';
    push @pfm_list, 'C:/Program Files/MikTex 2.9/fonts/type1/urw/bookman/ubkd8a.pfm';
    push @pfb_list, 'C:/Program Files (x86)/MikTex 2.9/fonts/type1/urw/bookman/ubkd8a.pfb';
    push @pfm_list, 'C:/Program Files (x86)/MikTex 2.9/fonts/type1/urw/bookman/ubkd8a.pfm';

} else {
    # Unix/Linux systems assumed. is this a standard location everyone has?
    push @pfb_list, '/usr/share/fonts/type1/gsfonts/a010013l.pfb';
    push @pfm_list, '/usr/share/fonts/type1/gsfonts/a010013l.pfm';
}

# This may or may not work on Macs ("darwin" string) and other platforms
# ("os2", "dos", "cygwin"). Might need some updates once the appropriate
# file paths are known. Suggestions are welcome for Windows and non-Windows
# font paths that could be tried.

# find a working file set (hopefully matched set of font and metrics!)
foreach (@pfb_list) {
    if (-f $_ && -r $_) {
        $pfb_file = $_; 
	last;
    }
}
foreach (@pfm_list) {
    if (-f $_ && -r $_) {
        $pfm_file = $_; 
	last;
    }
}

SKIP: {
    skip "Skipping Type1 tests... URW Gothic L Book font not found", $test_count
        unless (defined $pfb_file and defined $pfm_file);

    my $pdf = PDF::Builder->new();
#   my $font = $pdf->font($pfb_file, 'pfmfile' => $pfm_file); # was psfont()
    my $font = $pdf->psfont($pfb_file, 'pfmfile' => $pfm_file); # was psfont()

    # Do something with the font to see if it appears to have opened
    # properly.
    ok($font->glyphNum() > 0,
       q{Able to read a count of glyphs (>0) from a Type1 font});

    like($font->{'Name'}->val(), qr/^Ur/,
	 q{Font has the expected name});

}

1;

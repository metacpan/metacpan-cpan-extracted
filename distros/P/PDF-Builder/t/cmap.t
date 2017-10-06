use Test::More tests => 1;

use warnings;
use strict;

use PDF::Builder;

my $pdf = PDF::Builder->new();
my $font = $pdf->cjkfont('simplified');

is(ref($font), 'PDF::Builder::Resource::CIDFont::CJKFont',
   q{Check that .cmap files are being used});

#! /usr/bin/perl
#---------------------------------------------------------------------
# This example is hereby placed in the public domain.
# You may copy from it freely.
#
# This is an example of embedding a font using PostScript::File.
#
# Since this is a .PFB file, you'll need t1ascii to make this work:
#   http://www.lcdf.org/type/#t1utils
#---------------------------------------------------------------------

use strict;
use warnings;

use FindBin '$Bin';
use File::Spec;

use PostScript::File 1.05;      # Need cp1252 support

my $ps = PostScript::File->new(
  paper    => 'letter',
  reencode => 'cp1252', # Best available Unicode support (still not much)
  need_fonts => [],     # Not using the standard fonts at all
);

# Use catfile $Bin just in case we're not in the examples directory:
my $font = $ps->embed_font(File::Spec->catfile($Bin, 'UASquared.pfb'));

$ps->add_to_page( <<"END_PAGE" );
    /$font-iso findfont
    24 scalefont
    setfont
    72 300 moveto
    (Hello, world!) show
END_PAGE

printf "Wrote %s...\n", $ps->output("embed_font", $ENV{TMP});

#! /usr/bin/perl
#---------------------------------------------------------------------
# This example is hereby placed in the public domain.
# You may copy from it freely.
#
# This is a slightly less minimal Hello, World for PostScript::File.
#---------------------------------------------------------------------

use strict;
use warnings;

use PostScript::File 1.05;      # Need cp1252 support

my $ps = PostScript::File->new(
  paper    => 'letter',
  reencode => 'cp1252', # Best available Unicode support (still not much)
  need_fonts => ['Helvetica'],
);

# These characters are not in Latin-1, but they are in CP1252:
my $ldquo = chr(0x201C);        # \N{LEFT DOUBLE QUOTATION MARK}
my $rdquo = chr(0x201D);        # \N{RIGHT DOUBLE QUOTATION MARK}

$ps->add_to_page( <<"END_PAGE" );
    /Helvetica-iso findfont
    12 scalefont
    setfont
    72 300 moveto
    (${ldquo}Hello, world!$rdquo) show
END_PAGE

printf "Wrote %s...\n", $ps->output("hello_world", $ENV{TMP});

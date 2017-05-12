#! /usr/bin/perl
#---------------------------------------------------------------------
# This example is hereby placed in the public domain.
# You may copy from it freely.
#
# This is a minimal Hello, World for PostScript::File.
#---------------------------------------------------------------------

use strict;
use warnings;

use PostScript::File;

my $ps = PostScript::File->new();

$ps->add_to_page( <<END_PAGE );
    /Helvetica findfont
    12 scalefont
    setfont
    72 300 moveto
    (hello world) show
END_PAGE

printf "Wrote %s...\n", $ps->output("minimal", $ENV{TMP});

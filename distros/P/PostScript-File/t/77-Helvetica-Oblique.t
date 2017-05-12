#! /usr/bin/perl
#---------------------------------------------------------------------
# Compare pre-compiled Helvetica-Oblique metrics against Font::AFM
#---------------------------------------------------------------------

use strict;
use warnings;

use lib 't';
use Font_Test;

test_font('Helvetica-Oblique');

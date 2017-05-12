#! /usr/bin/perl
#---------------------------------------------------------------------
# Compare pre-compiled Helvetica-BoldOblique metrics against Font::AFM
#---------------------------------------------------------------------

use strict;
use warnings;

use lib 't';
use Font_Test;

test_font('Helvetica-BoldOblique');

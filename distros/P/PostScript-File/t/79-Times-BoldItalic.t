#! /usr/bin/perl
#---------------------------------------------------------------------
# Compare pre-compiled Times-BoldItalic metrics against Font::AFM
#---------------------------------------------------------------------

use strict;
use warnings;

use lib 't';
use Font_Test;

test_font('Times-BoldItalic');

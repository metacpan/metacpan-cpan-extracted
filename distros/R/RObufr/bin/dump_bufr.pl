#!/usr/bin/env perl
#
##  Copyright (c) 1995-2013 University Corporation for Atmospheric Research
## All rights reserved
#
my $pkgdoc = <<'EOD';
#/**----------------------------------------------------------------------    
# @file       dump_bufr.pl
#
# Produce an ASCII dump of the input BUFR file.
#
# @author     Doug Hunt
# @since      5/29/2013
# @usage      dump_bufr.pl BUFR_file
# -----------------------------------------------------------------------*/
EOD

$|++;  # set autoflush for STDOUT

use strict;
use warnings;

use PDL;
use RObufr;  # interface to BUFR library

if (@ARGV < 1) {
  print $pkgdoc;
  exit -1;
}

my $infile = shift;

print RObufr->new->read($infile)->print;

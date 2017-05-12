#!/usr/bin/perl
###########################################
# Mike Schilli, 2002 (m@perlmeister.com)
###########################################
use warnings;
use strict;

use Pod::HtmlTree qw(mkdoctree);

mkdoctree("/poddocs", "/srcpath");

#!/usr/bin/perl -w

# $Id: 10distribution.t 37 2008-03-09 01:10:00Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/t/10distribution.t $

use strict;
use Test::More;

eval 'require Test::Distribution';
plan( skip_all => 'Test::Distribution not installed' ) if $@;
Test::Distribution->import();

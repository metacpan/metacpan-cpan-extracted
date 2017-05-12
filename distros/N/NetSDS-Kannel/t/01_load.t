#!/usr/bin/env perl
#===============================================================================
#
#         FILE:  01_load.t
#
#  DESCRIPTION:  Check if all modules are loading without errors
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  23.11.2008 18:14:27 EET
#===============================================================================

use strict;
use warnings;

use Test::More tests => 3;                      # last test to print

BEGIN {
	use_ok('NetSDS::Kannel');
	use_ok('NetSDS::Kannel::Admin');
	use_ok('NetSDS::Feature::Kannel');
}



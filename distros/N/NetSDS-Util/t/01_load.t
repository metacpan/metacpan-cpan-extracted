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
#===============================================================================

use strict;
use warnings;

use Test::More tests => 10;                      # last test to print

BEGIN {
	use_ok('NetSDS::Util');
	use_ok('NetSDS::Util::Convert');
	use_ok('NetSDS::Util::DateTime');
	use_ok('NetSDS::Util::File');
	use_ok('NetSDS::Util::FileImport');
	use_ok('NetSDS::Util::Misc');
	use_ok('NetSDS::Util::String');
	use_ok('NetSDS::Util::Struct');
	use_ok('NetSDS::Util::Translit');
	use_ok('NetSDS::Util::Types');
}


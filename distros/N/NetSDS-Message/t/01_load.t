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
#      CREATED:  13.07.2008 23:48:53 EEST
#     REVISION:  $Id: 01_load.t 49 2008-07-30 08:31:41Z misha $
#===============================================================================

use strict;
use warnings;

use Test::More tests => 4;                      # last test to print

BEGIN {
	use_ok('NetSDS::Message');
	use_ok('NetSDS::Const::Message');
	use_ok('NetSDS::Message::SMS');
	use_ok('NetSDS::Util::SMS');
}


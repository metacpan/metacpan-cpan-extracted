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

use Test::More tests => 16;                      # last test to print

BEGIN {
	use_ok('NetSDS');
	use_ok('NetSDS::Class::Abstract');
	use_ok('NetSDS::Conf');
	use_ok('NetSDS::Const');
	use_ok('NetSDS::DBI');
	use_ok('NetSDS::DBI::Table');
	use_ok('NetSDS::EDR');
	use_ok('NetSDS::Feature');
	use_ok('NetSDS::Logger');
	use_ok('NetSDS::Session');
	use_ok('NetSDS::Template');
	use_ok('NetSDS::Translate');
	use_ok('NetSDS::App');
	use_ok('NetSDS::App::FCGI');
	use_ok('NetSDS::App::JSRPC');
	use_ok('NetSDS::App::SMTPD');
}


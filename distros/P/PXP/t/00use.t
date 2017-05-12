#!/usr/bin/perl -w
#

use strict;

use Test::More tests => 7;

BEGIN {
  use_ok('PXP');
  use_ok('PXP::PluginRegistry');
  use_ok('PXP::Config');
  use_ok('PXP::I18N');
  use_ok('PXP::Plugin');
  use_ok('PXP::ExtensionPoint');
  use_ok('PXP::ExtensionPointClass');
}

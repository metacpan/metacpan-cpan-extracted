#!/usr/bin/env perl
#

use strict;
use warnings;

use Module::Build;
Module::Build->new(
  module_name => 'SMS::SMS77',
  license     => 'perl',
  script_files => 'bin/sms77send'
)->create_build_script;

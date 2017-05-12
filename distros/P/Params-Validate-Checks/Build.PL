#! /usr/bin/perl


use warnings;
use strict;

use Module::Build;


Module::Build->new
(
  module_name => 'Params::Validate::Checks',
  license => 'perl',
  dist_author => 'Smylers <smylers@cpan.org>',
  dist_version_from => 'lib/Params/Validate/Checks.pm',
  requires =>
  {
    'Params::Validate' => 0,
  },
  build_requires =>
  {
    'Test::More' => 0,
    'Test::Exception' => 0,
    'Test::Warn' => 0,
  },
  add_to_cleanup => ['Params-Validate-Checks-*'],
  create_makefile_pl => 'traditional',
)->create_build_script;

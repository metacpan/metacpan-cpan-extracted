#! /usr/bin/perl


use warnings;
use strict;

use Module::Build;


Module::Build->new
(
  module_name => 'Params::Validate::Checks::Net',
  license => 'perl',
  dist_author => 'Smylers <smylers@cpan.org>',
  dist_version_from => 'lib/Params/Validate/Checks/Net.pm',
  requires =>
  {
    'Params::Validate::Checks' => 0,
    'Data::Validate::Domain' => 0.02,
    'Data::Validate::IP' => 0,
    'Regexp::Common' => 0,
  },
  build_requires =>
  {
    'Test::More' => 0,
  },
  add_to_cleanup => ['Params-Validate-Checks-Net-*'],
  create_makefile_pl => 'traditional',
)->create_build_script;

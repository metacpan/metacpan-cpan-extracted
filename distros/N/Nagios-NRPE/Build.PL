#!/usr/bin/perl
use 5.010_000;

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
  module_name => 'Nagios::NRPE',
  license => 'perl',
  dist_author => 'Andreas Marschke <andreas.marschke@googlemail.com>',
  meta_merge => {
    resources => {
      homepage => 'http://github.com/andreas-marschke/nagios-nrpe',
      repository => 'git://github.com/andreas-marschke/nagios-nrpe.git'
     },
    no_index => {
      directory => [qw/t xt/],
    }
   },
  configure_requires => {
    'Module::Build' => '0.31',
  },
  build_requires => {
    "Test::More" => 0,
    "Test::Pod::Coverage" => 0
  },
  requires => {
    "perl" => "5.010_000",
    "Convert::Binary::C" => 0,
    "constant" => 0,
    "IO::Socket" => 0,
    "IO::Socket::INET" => 0
  },
  dynamic_config => 0,
  recursive_test_files => 1,
  create_license => 1,
  test_files => 't/*.t xt/*.t',
 );

$build->create_build_script;

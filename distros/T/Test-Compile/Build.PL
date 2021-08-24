#! /usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new (
    module_name => 'Test::Compile',
    abstract_from => 'lib/Test/Compile.pm',
    dist_author => 'Evan Giles <egiles@cpan.org>',
    license  => 'perl',
    configure_requires => { 'Module::Build' => 0.38 },
    requires => {
       'perl'               => '5.10.0',
       'version'            => 0,
       'parent'             => '0.225',
       'Exporter'           => '5.68',
    },
    create_makefile_pl => 'traditional',
    meta_merge     => {
      resources => {
        repository => "http://github.com/egiles/test-compile",
      }
    },
);
$build->create_build_script;


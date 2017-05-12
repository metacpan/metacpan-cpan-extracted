#!/usr/bin/perl
use warnings;
use strict;

use Module::Build;

Module::Build->new(
    dist_author => "Tom Insam / Fotango",
    module_name => 'Template::TAL',
    license => 'perl',
    requires => {
      'perl' => '5.008', # unicode.
      'XML::LibXML' => 0,
      'Test::More' => 0,
      'Test::XML' => 0,
      'UNIVERSAL::require' => 0,
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
)->create_build_script;


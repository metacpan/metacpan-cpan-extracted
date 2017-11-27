#!/usr/bin/perl

use Module::Build;

Module::Build->new(
  dist_name     => 'TUWF',
  dist_version  => '1.1',
  dist_author   => 'Yoran Heling <projects@yorhel.nl>',
  dist_abstract => 'The Ultimate Website Framework',
  license       => 'mit',
  requires => {
    perl => '5.8.0',
  },
  recommends => {
    'PerlIO::gzip'    => 0,
    'FCGI'            => 0,
    'DBI'             => 0,
  },
  meta_merge => {
    resources => {
      repository => 'https://g.blicky.net/tuwf.git/'
    },
  },
  create_makefile_pl => 'traditional',
)->create_build_script;


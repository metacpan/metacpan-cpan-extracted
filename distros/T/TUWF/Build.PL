#!/usr/bin/perl

use Module::Build;

Module::Build->new(
  dist_name     => 'TUWF',
  dist_version  => '1.0',
  dist_author   => 'Yoran Heling <yorhel@cpan.org>',
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
      repository => 'http://g.blicky.net/tuwf.git/'
    },
  },
  create_makefile_pl => 'traditional',
)->create_build_script;


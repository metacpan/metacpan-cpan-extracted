#!/usr/bin/perl

use Module::Build;

Module::Build->new(
  dist_name     => 'TUWF',
  dist_version  => '1.2',
  dist_author   => 'Yoran Heling <projects@yorhel.nl>',
  dist_abstract => 'The Ultimate Website Framework',
  license       => 'mit',
  requires => {
    perl => '5.10.0',
  },
  recommends => {
    'DBI'                  => 0,
    'FCGI'                 => 0,
    'HTTP::Server::Simple' => 0,
    'JSON::XS'             => 0,
    'PerlIO::gzip'         => 0,
  },
  meta_merge => {
    resources => {
      repository => 'https://g.blicky.net/tuwf.git/',
      homepage   => 'https://dev.yorhel.nl/tuwf'
    },
  },
  create_makefile_pl => 'traditional',
)->create_build_script;


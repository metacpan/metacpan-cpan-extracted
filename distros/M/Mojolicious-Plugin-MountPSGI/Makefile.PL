#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::MountPSGI',
  VERSION_FROM => 'lib/Mojolicious/Plugin/MountPSGI.pm',
  AUTHOR       => '<Marcus Ramberg <mramberg@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '4.82',Plack=>0},
  test         => {TESTS => 't/*.t'},
  LICENSE      => 'perl_5',
  META_MERGE   => {
    resources => {
      bugtracker => 'https://github.com/marcusramberg/Mojolicious-Plugin-MountPSGI/issues',
      repository => 'https://github.com/marcusramberg/Mojolicious-Plugin-MountPSGI',
    },
    no_index => {directory => ['t']},
  },
);

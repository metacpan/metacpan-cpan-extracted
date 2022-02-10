#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  'ABSTRACT'   => 'Library of bindings to use the RESTful API of Podman.',
  'AUTHOR'     => 'Tobias Schaefer <github@blackox.org>',
  'DISTNAME'   => 'Podman',
  'META_MERGE' => {
    resources => {
      'bugtracker' => {web => 'https://github.com/tschaefer/podman-perl/issues'},
      'license'    => 'http://dev.perl.org/licenses',
      'homepage'   => 'https://github.com/tschaefer/podman-perl',
      'repository' => 'https://github.com/tschaefer/podman-perl.git',
    }
  },
  'NAME'         => 'Podman',
  'PREREQ_PM'    => {'Mojolicious' => '9.22',},
  'VERSION_FROM' => 'lib/Podman/Client.pm',
  'clean'        => {FILES    => 'Podman-*'},
  'dist'         => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
  ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl',) : ()),
);

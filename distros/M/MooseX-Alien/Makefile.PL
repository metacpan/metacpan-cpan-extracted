#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'MooseX::Alien',
  AUTHOR       => 'Graham Barr <gbarr@pobox.com>',
  VERSION_FROM => 'lib/MooseX/Alien.pm',
  PL_FILES     => {},
  PREREQ_PM => {
    'Moose' => 0,
    'Test::More' => 0,
  },
  dist     => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
);


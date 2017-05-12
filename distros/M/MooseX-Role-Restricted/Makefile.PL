#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'MooseX::Role::Restricted',
  AUTHOR       => 'Graham Barr <gbarr@pobox.com>',
  VERSION_FROM => 'lib/MooseX/Role/Restricted.pm',
  PL_FILES     => {},
  PREREQ_PM    => {
    'Moose'               => '0.90',
    'Test::More'          => 0,
    'Attribute::Handlers' => 0.88,
  },
);


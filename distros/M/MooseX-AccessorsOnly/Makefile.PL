#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'MooseX::AccessorsOnly',
  AUTHOR         => 'Matthew King (cpan:CHOHAG) <chohag@jtan.com>',
  ABSTRACT_FROM  => 'lib/MooseX/AccessorsOnly.pm',
  VERSION_FROM   => 'lib/MooseX/AccessorsOnly.pm',
  LICENSE        => 'wtfpl_2',
  PREREQ_PM      => {
    'perl'             => '5',
    # Explicitly does not depend on Moose or Moo so that the same
    # package can (eventually) be used for both.
  },
);

#!/usr/bin/perl

use warnings;
use strict;
use ExtUtils::MakeMaker;

# ExtUtils::MakeMaker on Debian is a developer release (?!?)
no warnings qw{numeric};

WriteMakefile(
  NAME          => 'Sys::Facter',
  AUTHOR        => q{Stanislaw Klekot <cpan@jarowit.net>},
  VERSION_FROM  => 'lib/Sys/Facter.pm',
  #ABSTRACT_FROM => 'lib/Sys/Facter.pm',
  EXE_FILES     => ['pffacter'],
  ($ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ('LICENSE'=> 'perl')
    : ()),
  PREREQ_PM => {
    Pfacter        => 0,
    POSIX          => 0,
    'Getopt::Long' => 0,
    YAML           => 0,
  },
  dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean         => { FILES => 'Facter-*' },
);

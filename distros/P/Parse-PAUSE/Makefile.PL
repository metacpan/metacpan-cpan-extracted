
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Parse-PAUSE',
  NAME      => 'Parse::PAUSE',
  AUTHOR    => 'Adam\ J\.\ Foxson',
  ABSTRACT  => 'Parses\ CPAN\ upload\ emails\ sent\ by\ PAUSE',
  VERSION   => '1.001',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Scalar::Util" => '0',
    "Module::Pluggable" => '0',
    "Encode::Newlines" => '0',
    "Encode" => '0',
    "Moose" => '0',
  },
);

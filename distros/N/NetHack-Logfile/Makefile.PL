
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'NetHack-Logfile',
  NAME      => 'NetHack::Logfile',
  AUTHOR    => 'Shawn\ M\ Moore\ \<sartak\@gmail\.com\>',
  ABSTRACT  => 'Parse and create NetHack logfiles',
  VERSION   => '1.00',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Sub::Exporter" => '0.01',
    "MooseX::Attributes::Curried" => '0.02',
    "Moose" => '0.78',
  },
);

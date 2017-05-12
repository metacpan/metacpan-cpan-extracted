
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Template-Plugin-Komma',
  NAME      => 'Template::Plugin::Komma',
  AUTHOR    => 'Uwe\ Voelker\ \<uwe\.voelker\@gmx\.de\>',
  ABSTRACT  => 'TT2 plugin to commify numbers (German format)',
  VERSION   => '0.07',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Template" => '2.0',
  },
);

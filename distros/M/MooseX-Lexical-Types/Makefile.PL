
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'MooseX-Lexical-Types',
  NAME      => 'MooseX::Lexical::Types',
  AUTHOR    => 'Florian\ Ragwitz\ \<rafl\@debian\.org\>',
  ABSTRACT  => 'automatically validate lexicals against Moose type constraints',
  VERSION   => '0.01',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::Exception" => '0',
    "namespace::autoclean" => '0',
    "Class::MOP" => '0',
    "Carp" => '0',
    "Test::More" => '0',
    "MooseX::Types" => '0.09',
    "Lexical::Types" => '0',
    "Variable::Magic" => '0',
    "Moose" => '0',
  },
);


use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'MooseX-Role-Matcher',
  NAME      => 'MooseX::Role::Matcher',
  AUTHOR    => 'Jesse\ Luehrs\ \<doy\ at\ tozt\ dot\ net\>',
  ABSTRACT  => 'generic object matching based on attributes and methods',
  VERSION   => '0.05',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0',
    "List::Util" => '0',
    "MooseX::Role::Parameterized" => '0.03',
    "Test::Deep" => '0',
    "List::MoreUtils" => '0',
  },
);

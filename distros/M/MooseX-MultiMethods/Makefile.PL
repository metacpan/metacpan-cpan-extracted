
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'MooseX-MultiMethods',
  NAME      => 'MooseX::MultiMethods',
  AUTHOR    => "Florian\ Ragwitz\ \<rafl\@debian\.org\>",
  ABSTRACT  => "Multi\ Method\ Dispatch\ based\ on\ Moose\ type\ constraints",
  VERSION   => '0.10',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "MooseX::Types::Moose" => '0',
    "namespace::autoclean" => '0',
    "aliased" => '0',
    "MooseX::Method::Signatures" => '0.29',
    "Sub::Install" => '0',
    "Devel::PartialDump" => '0',
    "Devel::Declare" => '0.004000',
    "MooseX::Types::VariantTable" => '0.03',
    "Moose" => '0',
  },
  test => {TESTS => 't/*.t'}
);


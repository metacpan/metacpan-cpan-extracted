use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Test::Classy',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Test/Classy.pm',
  ABSTRACT_FROM => 'lib/Test/Classy.pm',
  PREREQ_PM => {
    'Class::Data::Inheritable' => 0,
    'Class::Inspector'         => 0,
    'Data::Dump'               => 0,
    'Encode'                   => 0,
    'Module::Find'             => 0,
    'Sub::Install'             => 0,
    'Term::Encoding'           => 0,
    'Test::More'               => '0.47',
    'Test::UseAllModules'      => '0.09',
  },
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( LICENSE => 'perl' )
    : ()
  ),
);

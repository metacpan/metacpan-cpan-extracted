use 5.034000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Perlsac::rwsac',
  VERSION_FROM     => 'lib/Perlsac/rwsac.pm',
  ABSTRACT_FROM    => 'lib/Perlsac/rwsac.pm',
  AUTHOR           => 'Hobin Lim',
  LICENSE          => 'MIT',
  MIN_PERL_VERSION => '5.034000',
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
  },
);

use 5.008005;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'Router::XS',
  VERSION_FROM   => 'lib/Router/XS.pm',
  PREREQ_PM      => { 'Test::More' => 0, 'Exporter' => '5.57', 'Test::Fatal' => 0 },
  ABSTRACT_FROM  => 'lib/Router/XS.pm',
  AUTHOR         => 'David Farrell',
  CCFLAGS        => '-Wall -std=c99',
  OPTIMIZE       => '-O3',
  #DEFINE         => '-DDEBUG=1',
  LICENSE        => 'FreeBSD',
);

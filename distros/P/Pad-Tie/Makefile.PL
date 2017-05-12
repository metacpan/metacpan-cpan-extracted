use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Pad::Tie',
  AUTHOR        => 'Hans Dieter Pearcey <hdp@cpan.org>',
  VERSION_FROM  => 'lib/Pad/Tie.pm',
  ABSTRACT_FROM => 'lib/Pad/Tie.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More'           => 0,
    'Test::use::ok'        => 0,
    'Data::OptList'        => '0.101',
    'Lexical::Persistence' => '0.97',
    'Module::Pluggable'    => '3.1',
    'Devel::LexAlias'      => '0.04',
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Pad-Tie-*' },
);

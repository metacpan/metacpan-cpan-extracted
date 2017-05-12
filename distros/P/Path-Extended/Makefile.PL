use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;
use 5.006;

WriteMakefile(
  NAME          => 'Path::Extended',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Path/Extended.pm',
  ABSTRACT_FROM => 'lib/Path/Extended.pm',
  LICENSE => 'perl',
  META_MERGE => {
    resources => {
      repository => 'https://github.com/charsbar/path-extended',
    },
  },
  test => {RECURSIVE_TEST_FILES=>1},
);

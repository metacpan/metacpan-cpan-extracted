use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
  NAME          => 'Pod::PerldocJp',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Pod/PerldocJp.pm',
  ABSTRACT_FROM => 'lib/Pod/PerldocJp.pm',
  LICENSE => 'perl',
  EXE_FILES => [qw(perldocjp)],
  META_MERGE => {
    resources => {
      repository => 'https://github.com/charsbar/pod-perldocjp',
    },
  },
);

use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile 0.04;

WriteMakefile(
  NAME           => 'Module::New',
  AUTHOR         => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM   => 'lib/Module/New.pm',
  ABSTRACT_FROM  => 'lib/Module/New.pm',
  EXE_FILES => [grep {-f $_} qw/module_new new/],
  LICENSE => 'perl',
  META_MERGE => {
    resources => {
      repository => 'https://github.com/charsbar/module-new',
    },
  },
);

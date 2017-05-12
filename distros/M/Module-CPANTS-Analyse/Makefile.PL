use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
  NAME => 'Module::CPANTS::Analyse',
  AUTHOR => [
    'Thomas Klausner <domm@cpan.org>',
    'Kenichi Ishigaki <ishigaki@cpan.org>',
  ],
  ABSTRACT_FROM => 'lib/Module/CPANTS/Analyse.pm',
  VERSION_FROM => 'lib/Module/CPANTS/Analyse.pm',
  LICENSE => 'perl',

  META_MERGE => {
    resources => {
      homepage => 'http://cpants.cpanauthors.org',
      repository => 'https://github.com/cpants/Module-CPANTS-Analyse',
      bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Module-CPANTS-Analyse',
    },
    keywords => [
      'CPANTS','kwalitee',
    ],
  },

  test => {TESTS => 't/*.t t/*/*.t'},
);

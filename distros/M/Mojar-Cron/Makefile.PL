use 5.010_001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojar::Cron',
  VERSION_FROM => 'lib/Mojar/Cron.pm',
  ABSTRACT     => 'Cron-style time patterns and algorithm',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {perl => 5.016_001},
    resources => {
      homepage    => 'https://niczero.github.io/mojar',
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/niczero/mojar-cron',
      bugtracker  => 'https://github.com/niczero/mojar-cron/issues'
    },
    no_index => {directory => ['test']}
  },
  BUILD_REQUIRES => {'Test::More' => 0},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.3},
  PREREQ_PM => {
    Mojolicious => 9.15,
    Mojar       => 2.05
  },
  test => {TESTS => 'test/*.t'}
);

use 5.010_001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojar',
  VERSION_FROM => 'lib/Mojar.pm',
  ABSTRACT     => 'Interface integration toolkit',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    no_index  => {directory => ['test']},
    requires  => {perl => 5.010_001},
    resources => {
      homepage   => 'http://niczero.github.io/mojar',
      license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository => 'http://github.com/niczero/mojar',
      bugtracker => 'http://github.com/niczero/mojar/issues',
      x_IRC      => 'irc://irc.perl.org/#mojo'
    }
  },
  BUILD_REQUIRES => {'Test::More' => 0},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.3},
  PREREQ_PM => {Mojolicious => 7.15},
  EXE_FILES => [],
  test => {TESTS => 'test/*.t'}
);

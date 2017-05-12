use 5.010_001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Log::Timestamp',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Log/Timestamp.pm',
  ABSTRACT     => 'Plugin for customised log timestamps',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    no_index  => {directory => ['test']},
    requires  => {perl => 5.010_001},
    resources => {
      license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository => 'http://github.com/niczero/mojolicious-plugin-log-timestamp',
      bugtracker => 'http://github.com/niczero/mojolicious-plugin-log-timestamp/issues',
      x_IRC      => 'irc://irc.perl.org/#mojo'
    }
  },
  BUILD_REQUIRES     => {'Test::More' => 0},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.3},
  PREREQ_PM => {
    Mojolicious => 7.15,
    Mojar       => 2
  },
  EXE_FILES          => [],
  test               => {TESTS => 'test/*.t'}
);

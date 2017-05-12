use 5.010_001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Log::Access',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Log/Access.pm',
  ABSTRACT     => 'Plugin for production-tier access logging',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    no_index => {directory => [qw(test)]},
    requires  => {perl => 5.010_001},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'http://github.com/niczero/mojolicious-plugin-log-access',
      bugtracker  => 'http://github.com/niczero/mojolicious-plugin-log-access/issues',
      x_IRC      => 'irc://irc.perl.org/#mojo'
    }
  },
  BUILD_REQUIRES => {'Test::More' => 0},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.3},
  PREREQ_PM => {Mojolicious => 7.15},
  EXE_FILES => [],
  test => {TESTS => 'test/*.t'}
);

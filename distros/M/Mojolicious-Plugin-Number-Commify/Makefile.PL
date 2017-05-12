use 5.010_001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Number::Commify',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Number/Commify.pm',
  ABSTRACT     => 'Plugin for readable numbers',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    no_index  => {directory => ['test']},
    requires  => {perl => 5.010_001},
    resources => {
      license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository => 'https://github.com/niczero/mojolicious-plugin-number-commify',
      bugtracker => 'https://github.com/niczero/mojolicious-plugin-number-commify/issues',
      x_IRC      => 'irc://irc.perl.org/#mojo'
    }
  },
  BUILD_REQUIRES => {'Test::More' => 0},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.3},
  PREREQ_PM => {Mojolicious => 7.15},
  EXE_FILES => [],
  test => {TESTS => 'test/*.t'}
);

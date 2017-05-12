use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

# Mojolicious 5.27 first introduced support for nested helpers
WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Restify',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Restify.pm',
  ABSTRACT     => 'Route shortcuts & helpers for REST collections',
  AUTHOR       => 'Paul Williams <kwakwa@cpan.org>',
  LICENSE      => 'artistic_2',
  PREREQ_PM    => {'Mojolicious' => '5.27'},
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
      bugtracker => 'https://github.com/kwakwaversal/mojolicious-plugin-restify/issues',
      repository => 'https://github.com/kwakwaversal/mojolicious-plugin-restify.git',
    },
    no_index => {directory => ['t']}
  },
  test         => {TESTS => 't/*.t'}
);

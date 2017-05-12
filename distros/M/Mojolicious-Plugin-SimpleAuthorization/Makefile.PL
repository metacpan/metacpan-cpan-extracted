use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::SimpleAuthorization',
  VERSION_FROM => 'lib/Mojolicious/Plugin/SimpleAuthorization.pm',
  ABSTRACT     => 'Simple role-based authorization',
  AUTHOR       => 'Paul Williams <kwakwa@cpan.org>',
  LICENSE      => 'artistic_2',
  PREREQ_PM    => {'Mojolicious' => '4.72'},
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
      bugtracker => 'https://github.com/kwakwaversal/mojolicious-plugin-simpleauthorization/issues',
      repository => 'https://github.com/kwakwaversal/mojolicious-plugin-simpleauthorization.git',
    },
    no_index => {directory => ['t']}
  },
  test         => {TESTS => 't/*.t'}
);

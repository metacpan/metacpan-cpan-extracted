use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Qooxdoo',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Qooxdoo.pm',
  ABSTRACT     => 'Qooxdoo JSON-RPC support for the Mojolicious Perl framework',
  AUTHOR       => 'Tobias Oetiker <tobi@oetiker.ch>',
  LICENSE      => 'artistic_2',
  PREREQ_PM    => {
    'Mojolicious' => '7.26'
  },
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/oetiker/Mojolicious-Plugin-Qooxdoo',
      bugtracker  => 'https://github.com/oetiker/Mojolicious-Plugin-Qooxdoo/issues'
    },
    no_index => {directory => ['t','example','setup']}
  },
# EXE_FILES => ['script/hypnotoad', 'script/mojo', 'script/morbo'],
  test => {TESTS => 't/*.t'}
);

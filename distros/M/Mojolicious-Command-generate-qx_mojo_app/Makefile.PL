use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Command::generate::qx_mojo_app',
  VERSION_FROM => 'lib/Mojolicious/Command/generate/qx_mojo_app.pm',
  ABSTRACT     => 'Mojo generator for a qooxdoo mojolicious app',
  AUTHOR       => 'Tobias Oetiker <tobi@oetiker.ch>',
  LICENSE      => 'artistic_2',
  PREREQ_PM    => {
    'Mojolicious' => '5.0',
    'Mojolicious::Plugin::Qooxdoo' => '0.901',
  },
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/oetiker/qx-mojo-app',
      bugtracker  => 'https://github.com/oetiker/qx-mojo-app/issues'
    },
    no_index => {directory => ['t','lib/Mojolicious/Command/generate/qx_mojo_app']}
  },
  test => {TESTS => 't/*.t'}
);

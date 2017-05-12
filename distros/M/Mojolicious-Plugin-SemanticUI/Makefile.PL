use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::SemanticUI',
  VERSION_FROM => 'lib/Mojolicious/Plugin/SemanticUI.pm',
  AUTHOR       => q{Красимир Беров <berov@cpan.org>},
  LICENSE      => 'lgpl_3_0',
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license    => 'http://opensource.org/licenses/LGPL-3.0',
      repository => 'https://github.com/kberov/Mojolicious-Plugin-SemanticUI',
      bugtracker => 'https://github.com/kberov/Mojolicious-Plugin-SemanticUI/issues'
    },
    no_index => {directory => ['t']}
  },
  PREREQ_PM => {'Mojolicious' => '5.39'},
  test      => {TESTS         => 't/*.t'}
);

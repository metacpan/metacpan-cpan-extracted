use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::RenderSteps',
  VERSION_FROM => 'lib/Mojolicious/Plugin/RenderSteps.pm',
  AUTHOR       => 'Marcus Ramberg <mramberg@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '6.10'},
  test         => {TESTS => 't/*.t'},
  META_MERGE   => {
    resources => {
      license => 'http://www.opensource.org/licenses/artistic-license-2.0',
      bugtracker =>
        'https://github.com/marcusramberg/Mojolicious-Plugin-RenderSteps/issues',
      repository =>
        'https://github.com/marcusramberg/Mojolicious-Plugin-RenderSteps',
    },
  },

);

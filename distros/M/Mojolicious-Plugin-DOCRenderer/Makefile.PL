use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::DOCRenderer',
  VERSION_FROM => 'lib/Mojolicious/Plugin/DOCRenderer.pm',
  ABSTRACT     => 'Browses online documentation of your Mojolicious application',
  AUTHOR       => 'Viliam Pucik <viliam.pucik@gmail.com>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    'meta-spec'   => {version => 2},
    no_index      => {directory => ['t']},
    prereqs       => {runtime => {requires => {perl => '5.010001'}}},
    resources => {
      bugtracker  => {web => 'https://github.com/viliampucik/Mojolicious-Plugin-DocRenderer/issues'},
      homepage    => 'https://github.com/viliampucik/Mojolicious-Plugin-DocRenderer',
      license     => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository  => {
        type => 'git',
        url  => 'https://github.com/viliampucik/Mojolicious-Plugin-DocRenderer.git',
        web  => 'https://github.com/viliampucik/Mojolicious-Plugin-DocRenderer',
      },
    },
  },
  PREREQ_PM    => {'Mojolicious' => '7.43'},
  test         => {TESTS => 't/*.pl'}
);

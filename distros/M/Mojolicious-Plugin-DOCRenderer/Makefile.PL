use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::DOCRenderer',
  VERSION_FROM => 'lib/Mojolicious/Plugin/DOCRenderer.pm',
  ABSTRACT     => 'Browses online documentation of your Mojolicious application',
  AUTHOR       => 'Viliam Pucik <viliam.pucik@gmail.com>',
  LICENSE      => 'artistic_2',
  PREREQ_PM    => {'Mojolicious' => '4.99'},
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      homepage    => 'https://github.com/viliampucik/Mojolicious-Plugin-DocRenderer',
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/viliampucik/Mojolicious-Plugin-DocRenderer',
      bugtracker  => 'https://github.com/viliampucik/Mojolicious-Plugin-DocRenderer/issues'
    },
    no_index => {directory => ['t']}
  },
  test         => {TESTS => 't/*.pl'}
);

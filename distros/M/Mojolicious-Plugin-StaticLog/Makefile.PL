use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::StaticLog',
  VERSION_FROM => 'lib/Mojolicious/Plugin/StaticLog.pm',
  AUTHOR       => 'Frank Carnovale <frankc@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '8.02'},
  LICENSE      => 'artistic_2', 
  test         => {TESTS => 't/*.t'},
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['t']},
    prereqs        => {runtime => {requires => {perl => '5.010001'}}},
    resources      => {
        bugtracker => {web => 'https://github.com/frank-carnovale/Mojolicious-Plugin-StaticLog/issues'},
        license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
        repository => {
            type => 'git',
            url  => 'https://github.com/frank-carnovale/Mojolicious-Plugin-StaticLog.git',
            web  => 'https://github.com/frank-carnovale/Mojolicious-Plugin-StaticLog',
        },
    },
  },
);

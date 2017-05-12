use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Tables',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Tables.pm',
  ABSTRACT     => 'Quickstart and grow a Tables-Maintenance Webapp',
  AUTHOR       => 'Frank Carnovale <frankc@cpan.org>',
  LICENSE      => 'artistic_2',
  PREREQ_PM    => {'Mojolicious' => '6.44',
                   'DBIx::Class::Core' => 0,
                   'DBIx::Class::Schema' => 0,
                   'DBIx::Class::Schema::Loader' => '0.07045',
                   'DBIx::Class::Schema::Loader::Dynamic' => '1.05' },
  EXE_FILES    => ['bin/tables'],
  test         => {TESTS => 't/*.t'},
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['t']},
    prereqs        => {runtime => {requires => {perl => '5.010001'}}},
    resources    => {
        bugtracker => {web => 'https://github.com/frank-carnovale/Mojolicious-Plugin-Tables/issues'},
        license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
        repository => {
            type => 'git',
            url  => 'https://github.com/frank-carnovale/Mojolicious-Plugin-Tables.git',
            web  => 'https://github.com/frank-carnovale/Mojolicious-Plugin-Tables',

        },
    },
  },
);

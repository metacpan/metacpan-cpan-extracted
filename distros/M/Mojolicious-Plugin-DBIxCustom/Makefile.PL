use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME               => 'Mojolicious::Plugin::DBIxCustom',
  AUTHOR             => q{wfso <461663376@qq.com>},
  VERSION_FROM       => 'lib/Mojolicious/Plugin/DBIxCustom.pm',
  ABSTRACT_FROM      => 'lib/Mojolicious/Plugin/DBIxCustom.pm',
  LICENSE            => 'mit',
  PL_FILES           => {},
  META_MERGE         => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    prereqs        => {runtime => {requires => {perl => '5.010001'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/wfso/Mojolicious-Plugin-DBIxCustom/issues'},
      homepage   => 'https://github.com/wfso/Mojolicious-Plugin-DBIxCustom/wiki',
      license    => ['https://opensource.org/licenses/MIT'],
      repository => {
        type => 'git',
        url  => 'https://github.com/wfso/Mojolicious-Plugin-DBIxCustom.git',
        web  => 'https://github.com/wfso/Mojolicious-Plugin-DBIxCustom',
      }
    },
  },
  MIN_PERL_VERSION   => '5.010001',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  BUILD_REQUIRES     => {
    'Test::More' => '0',
  },
  PREREQ_PM          => {
    Mojolicious => '7.48',
    'DBIx::Custom' => '0.40',
    
  },
  dist               => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
  clean              => {FILES => 'Mojolicious-Plugin-DBIxCustom-*'},
);

use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME               => 'Mojolicious::Services',
  AUTHOR             => q{wfso <461663376@qq.com>},
  VERSION_FROM       => 'lib/Mojolicious/Services.pm',
  ABSTRACT_FROM      => 'lib/Mojolicious/Services.pm',
  LICENSE            => 'mit',
  META_MERGE         => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    prereqs        => {runtime => {requires => {perl => '5.010001'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/wfso/Mojolicious-Services/issues'},
      homepage   => 'https://github.com/wfso/Mojolicious-Services/wiki',
      license    => ['https://opensource.org/licenses/MIT'],
      repository => {
        type => 'git',
        url  => 'https://github.com/wfso/Mojolicious-Services.git',
        web  => 'https://github.com/wfso/Mojolicious-Services',
      }
    },
  },
  PL_FILES           => {},
  MIN_PERL_VERSION   => '5.010001',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  BUILD_REQUIRES     => {
    'Test::More' => '0',
  },
  PREREQ_PM          => {
    Mojolicious => '7.48'
  },
  dist               => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
  clean              => {FILES => 'Mojolicious-Services-*'},
);

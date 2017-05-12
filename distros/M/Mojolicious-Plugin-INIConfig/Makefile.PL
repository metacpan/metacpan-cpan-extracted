use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::INIConfig',
    AUTHOR              => 'Yuki Kimoto <kimoto.yuki@gmail.com>',
    VERSION_FROM        => 'lib/Mojolicious/Plugin/INIConfig.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/INIConfig.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
      'Config::Tiny' => '2.14',
      'Mojolicious' => '3.84'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-INIConfig-*' },
    test => {TESTS => 't/*.t'}
);

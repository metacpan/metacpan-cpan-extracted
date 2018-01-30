use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Paging',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Paging.pm',
  AUTHOR           => q{wfso <461663376@qq.com>},
  VERSION_FROM     => 'lib/Mojolicious/Plugin/Paging.pm',
  ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/Paging.pm',
  LICENSE          => 'artistic_2',
  PL_FILES         => {},
  MIN_PERL_VERSION => '5.10.1',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  BUILD_REQUIRES => {
    'Test::More' => '0',
  },
  PREREQ_PM => {
    #'ABC'              => '1.6',
    #'Foo::Bar::Module' => '5.0401',
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Mojolicious-Plugin-Paging-*' },
);


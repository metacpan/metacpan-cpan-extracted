use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME               => 'Mojolicious::Plugin::ExportExcel',
  AUTHOR             => q{WFSO <461663376@qq.com>},
  VERSION_FROM       => 'lib/Mojolicious/Plugin/ExportExcel.pm',
  ABSTRACT_FROM      => 'lib/Mojolicious/Plugin/ExportExcel.pm',
  LICENSE            => 'mit',
  PL_FILES           => {},
  MIN_PERL_VERSION   => '5.006',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  BUILD_REQUIRES     => {
    'Test::More' => '0',
  },
  PREREQ_PM          => {
    'Spreadsheet::WriteExcel' => '2.40',
    Mojolicious               => '7.70'
    #'Foo::Bar::Module' => '5.0401',
  },
  dist               => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
  clean              => {FILES => 'Mojolicious-Plugin-ExportExcel-*'},
);

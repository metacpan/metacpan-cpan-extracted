use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::SQLiteViewerLite',
    AUTHOR              => q{Yuki Kimoto <kimoto.yuki@gmail.com>},
    VERSION_FROM        => 'lib/Mojolicious/Plugin/SQLiteViewerLite.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/SQLiteViewerLite.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Mojolicious' => '2.59',
        'Validator::Custom' => '0.1426',
        'DBIx::Custom' => '0.25',
        'Data::Page' => '2.02'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-SQLiteViewerLite-*' },
);

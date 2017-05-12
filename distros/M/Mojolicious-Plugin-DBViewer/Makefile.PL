use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::DBViewer',
    AUTHOR              => q{Yuki Kimoto <kimoto.yuki@gmail.com>},
    VERSION_FROM        => 'lib/Mojolicious/Plugin/DBViewer.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/DBViewer.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'Mojolicious'       => '2.59',
        'DBIx::Custom'      => '0.40',
        'Data::Page'        => '2.02',
        'Validator::Custom' => '1.0201',
        'DBIx::Connector'   => '0.52',
        'Mojolicious::Plugin::AutoRoute' => '0.12'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-DBViewer-*' },
);

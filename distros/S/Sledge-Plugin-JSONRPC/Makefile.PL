use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sledge::Plugin::JSONRPC',
    AUTHOR              => 'Atsushi Kobayashi <nekokak@gmail.com>',
    VERSION_FROM        => 'lib/Sledge/Plugin/JSONRPC.pm',
    ABSTRACT_FROM       => 'lib/Sledge/Plugin/JSONRPC.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'JSON::Syck' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sledge-Plugin-JSONRPC-*' },
);

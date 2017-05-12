use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sledge::Plugin::Paginate',
    AUTHOR              => 'Atsushi Kobayashi <nekokak@gmail.com>',
    VERSION_FROM        => 'lib/Sledge/Plugin/Paginate.pm',
    ABSTRACT_FROM       => 'lib/Sledge/Plugin/Paginate.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sledge-Plugin-Paginate-*' },
);

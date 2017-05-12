use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sledge::Plugin::RedirectReferer',
    AUTHOR              => 'Atsushi Kobayashi <nekokak@gmail>',
    VERSION_FROM        => 'lib/Sledge/Plugin/RedirectReferer.pm',
    ABSTRACT_FROM       => 'lib/Sledge/Plugin/RedirectReferer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'URI'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sledge-Plugin-RedirectReferer-*' },
);

# vi:set ft=perl:
use strict;
use warnings;

return {
    NAME   => 'Sys::GetRandom',
    AUTHOR => q{Lukas Mai <l.mai@web.de>},

    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'     => 0,
        'Exporter' => '5.57',
        'XSLoader' => 0,
        'strict'   => 0,
        'warnings' => 0,
    },
    DEVELOP_REQUIRES => {
        'Test::Pod' => 1.22,
    },

    depend => {
        Makefile => '$(VERSION_FROM)',
    },

    REPOSITORY => [ github => 'mauke' ],
};

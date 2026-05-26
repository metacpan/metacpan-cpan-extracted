# vi:set ft=perl:
use strict;
use warnings;

require './lib/Sys/GetRandom/PP.pm'
    unless $ENV{PERL_SYS_GETRANDOM_PP_FORCE_INSTALL};

return {
    NAME   => 'Sys::GetRandom::PP',
    AUTHOR => q{Lukas Mai <l.mai@web.de>},

    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'Test2::V0' => 0,
    },
    PREREQ_PM => {
        'Carp'     => 0,
        'Config'   => 0,
        'Exporter' => '5.57',
        'constant' => '1.03',
        'strict'   => 0,
        'warnings' => 0,
    },
    DEVELOP_REQUIRES => {
        'Pod::Markdown::Githubert' => 0,
        'Test::Pod'                => 1.22,
    },

    REPOSITORY => [ codeberg => 'mauke' ],
    BUGTRACKER => 'https://codeberg.org/mauke/Sys-GetRandom-PP/issues',
};

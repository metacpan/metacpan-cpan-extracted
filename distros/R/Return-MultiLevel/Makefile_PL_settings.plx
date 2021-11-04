use strict;
use warnings;

return {
    NAME   => 'Return::MultiLevel',
    AUTHOR => q{Lukas Mai <l.mai@web.de>},

    MIN_PERL_VERSION => '5.8.0',
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'Test::Fatal' => 0,
        'Test::More'  => 0,
    },
    PREREQ_PM => {
        'Carp'        => 0,
        'Data::Munge' => '0.07',
        'Exporter'    => 0,
        'parent'      => 0,
        'strict'      => 0,
        'warnings'    => 0,
    },
    RECOMMENDS => {
        'Scope::Upper' => '0.29',
    },
    DEVELOP_REQUIRES => {
        'Test::Pod' => 1.22,
    },

    REPOSITORY => [ github => 'uperl' ],
};

use strict;
use warnings;

return {
    NAME   => 'Switch::Plain',
    AUTHOR => q{Lukas Mai <l.mai@web.de>},

    MIN_PERL_VERSION => '5.14.0',
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'strict'      => 0,
        'Test::More'  => 0,
    },
    PREREQ_PM => {
        'Carp'     => 0,
        'XSLoader' => 0,
        'warnings' => 0,
    },
    DEVELOP_REQUIRES => {
        'Test::Pod' => 1.22,
    },

    depend => {
        Makefile    => '$(VERSION_FROM)',
        '$(OBJECT)' => join(' ', glob 'hax/*.c.inc'),
    },

    bonus => { github => 'mauke' },
};

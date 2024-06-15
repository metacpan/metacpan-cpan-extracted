# vi:set ft=perl:
use strict;
use warnings;

my $name = 'Sys::GetRandom::PP';
(my $dist = $name) =~ s!::!-!g;
(my $module = $name . '.pm') =~ s!::!/!g;

return {
    NAME   => $name,
    AUTHOR => q{Lukas Mai <l.mai@web.de>},

    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'Test2::V0' => 0,
    },
    PREREQ_PM => {
        'Carp'     => 0,
        'Exporter' => '5.57',
        'constant' => '1.03',
        'strict'   => 0,
        'warnings' => 0,
    },

    PL_FILES => {
        '_Bits.pm.PL' => '_Bits.pm',
    },
    PM => {
        "lib/$module" => "\$(INST_LIB)/$module",
        '_Bits.pm'    => '$(INST_ARCHLIB)/Sys/GetRandom/PP/_Bits.pm',
    },
    clean => {
        FILES => "$dist-* _Bits.pm",
    },

    REPOSITORY => [ github => 'mauke' ],
};

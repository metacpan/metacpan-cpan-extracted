use strict;
use Panda::Install;

write_makefile(
    NAME      => 'Panda::Export',
    PREREQ_PM => {'Panda::XS' => '1.1.1'}, # need XS_HV_ITER
    CPLUS     => 11,
    SRC       => 'src',
    INC       => '-Isrc',
    BIN_DEPS  => 'Panda::XS',
    BIN_SHARE => {
        CPLUS    => 11,
        INCLUDE  => {'src' => '/'},
    },
    OPTIMIZE => '-g0 -O2',
    CCFLAGS => '-Wall -Wextra -Wno-nonnull',
    #CC => 'clang++',
);

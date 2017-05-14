use strict;
use Panda::Install;

write_makefile(
    NAME          => 'Panda::Date',
    VERSION_FROM  => 'lib/Panda/Date.pm',
    ABSTRACT_FROM => 'lib/Panda/Date.pod',
    PREREQ_PM     => {
        'Panda::Export' => 0,
        'Panda::Time'   => '3.1.2',
    },
    SRC           => 'src',
    INC           => '-Isrc',
    TYPEMAPS      => 'typemap',
    BIN_DEPS      => ['Panda::Time', 'CPP::panda::lib'],
    BIN_SHARE     => {
        INCLUDE  => {'src' => '/'},
        TYPEMAPS => {'typemap' => ''},
    },
    CCFLAGS  => '-Wall -Wextra',
    OPTIMIZE => '-g0 -O2',
    #CC => 'clang++',
);

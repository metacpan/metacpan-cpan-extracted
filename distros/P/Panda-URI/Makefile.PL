use strict;
use Panda::Install;

write_makefile(
    NAME          => 'Panda::URI',
    VERSION_FROM  => 'lib/Panda/URI.pm',
    ABSTRACT_FROM => 'lib/Panda/URI.pod',
    PREREQ_PM     => {
        'Panda::Export' => 0,
        'Panda::Lib'    => '1.3.0', # need new string, string_view and related
    },
    CPLUS         => 11,
    SRC           => 'src',
    INC           => '-Isrc -I/usr/local/include',
    TYPEMAPS      => 'typemap',
    BIN_DEPS      => 'Panda::Lib',
    BIN_SHARE     => {
        CPLUS    => 11,
        INCLUDE  => {'src' => '/'},
        TYPEMAPS => {'typemap' => ''},
    },
    CCFLAGS  => '-Wall -Wextra',
    OPTIMIZE => '-g0 -O2',
    #CC => 'clang++',
);

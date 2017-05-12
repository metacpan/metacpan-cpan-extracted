use strict;
use Config;
use Panda::Install;

my $ivbits = $Config{ivsize}*8;

write_makefile(
    NAME      => 'Panda::Time',
    PREREQ_PM => {
        'Panda::Export' => 0,
        'Panda::Lib'    => '1.3.0', # endian.h
    },
    CPLUS     => 11,
    SRC       => 'src',
    INC       => '-Isrc',
    DEFINE    => $ENV{TEST_FULL} ? '-DTEST_FULL' : '',
    TYPEMAPS  => "typemap$ivbits",
    PAYLOAD   => {'zoneinfo' => ''},
    BIN_DEPS  => 'Panda::Lib',
    BIN_SHARE => {
        CPLUS    => 11,
        INCLUDE  => {'src' => '/'},
        TYPEMAPS => {"typemap$ivbits" => ''},
    },
    CCFLAGS  => '-Wall -Wextra',
    OPTIMIZE => '-g0 -O2',
#    CC => 'clang++',
);

use 5.018;
use Config;
use Panda::Install;

my $ivbits = $Config{ivsize}*8;

write_makefile(
    NAME          => 'Panda::XS',
    VERSION_FROM  => 'lib/Panda/XS.pm',
    ABSTRACT_FROM => 'lib/Panda/XS.pod',
    CPLUS         => 11,
    SRC           => ['src', $ENV{TEST_FULL} ? 't/src' : ()],
    INC           => '-Isrc',
    DEFINE        => $ENV{TEST_FULL} ? '-DTEST_FULL' : '',
    TYPEMAPS      => ['typemap', "typemap$ivbits", 'testmap'],
    BIN_SHARE     => {
        CPLUS    => 11,
        INCLUDE  => {
            'src'                    => '/',
            'src/algorithm_perlsafe' => '/algorithm_perlsafe',
        },
        XSOPT    => '-hiertype',
        TYPEMAPS => {
            'typemap'        => '',
            "typemap$ivbits" => '',
        },
    },
    MIN_PERL_VERSION => '5.18.0', # required for GV_SUPER
    CCFLAGS          => '-Wall -Wextra',
    OPTIMIZE         => '-g0 -O2',
    #CC => 'clang++',
);

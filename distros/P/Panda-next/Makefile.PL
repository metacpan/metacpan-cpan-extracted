use 5.018;
use Config;
use Panda::Install;

my %params = (
    NAME          => 'Panda::next',
    VERSION_FROM  => 'lib/Panda/next.pm',
    ABSTRACT_FROM => 'lib/Panda/next.pod',
    CPLUS         => 11,
    SRC           => ['src'],
    INC           => '-Isrc',
    XS            => {'next.xs' => 'next.cc'},
    BIN_SHARE     => {
        CPLUS    => 11,
        INCLUDE  => {'src' => '/'},
    },
    MIN_PERL_VERSION => '5.12.0',
    CCFLAGS          => '-Wall -Wextra',
    OPTIMIZE         => '-g0 -O3',
    #OPTIMIZE         => '-g -O3',
    #CC => 'clang++',
    test => {TESTS => 't/*.t t/perl/*.t'}
);

write_makefile(%params);

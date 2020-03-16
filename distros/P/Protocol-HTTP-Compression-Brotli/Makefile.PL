use 5.018;
use Config;
use XS::Install;

my %params = (
    NAME          => 'Protocol::HTTP::Compression::Brotli',
    TEST_REQUIRES => {'Test::More' => 0},
    CPLUS         => 11,
    SRC           => ['src'],
    INC           => '-Isrc',
    BIN_DEPS      => ['Protocol::HTTP', 'XS::libbrotli'],
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    test      => {
        SRC                  => 't',
        RECURSIVE_TEST_FILES => 1,
        BIN_DEPS             => 'Test::Catch',
    },
);

write_makefile(%params);


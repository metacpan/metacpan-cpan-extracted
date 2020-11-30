use 5.012;
use XS::Install;

my %params = (
    NAME          => 'Protocol::WebSocket::Fast',
    CPLUS         => 11,
    TEST_REQUIRES => {'Test::Exception' => 0, 'Test::Warnings' => 0, 'Test::Fatal' => 0},
    BIN_DEPS      => ['Export::XS', 'URI::XS', 'Encode::Base2N', 'Protocol::HTTP'],
    PKG_CONFIG    => $^O eq 'darwin' ? 'libcrypto' : '',
    LINK          => '-lz -lcrypto',
    SRC           => 'src',
    INC           => '-Isrc',
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    test          => {
        SRC                  => 't',
        RECURSIVE_TEST_FILES => 1,
        BIN_DEPS             => 'Test::Catch',
    },
);

write_makefile(%params);

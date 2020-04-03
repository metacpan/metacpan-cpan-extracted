use 5.012;
use XS::Install;

my %params = (
    NAME          => 'Protocol::WebSocket::XS',
    CPLUS         => 11,
    TEST_REQUIRES => {'Test::Exception' => 0, 'Test::Warnings' => 0, 'Test::Fatal' => 0},
    BIN_DEPS      => ['Export::XS', 'URI::XS', 'Encode::Base2N', 'Protocol::HTTP'],
    LIBS          => ['-lcrypto -lz'],
    SRC           => 'src',
    INC           => '-Isrc -I/usr/local/opt/openssl/include',
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    test          => {
        SRC                  => 't',
        RECURSIVE_TEST_FILES => 1,
        BIN_DEPS             => 'Test::Catch',
    },
);

if ($ENV{SANITIZE}) {
    ($params{CCFLAGS}||='') .= ' -fsanitize=undefined -fsanitize=address -fno-omit-frame-pointer';
    $params{LIBS}[0] .= ' -lubsan -lasan'; #sanitizer
}

write_makefile(%params);

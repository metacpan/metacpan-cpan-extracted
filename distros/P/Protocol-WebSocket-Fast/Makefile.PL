use 5.012;
use XS::Install;

my $cmake_project = "panda-protocol-websocket";
my $cmake_tests   = "$cmake_project-tests";

my %params = (
    NAME          => 'Protocol::WebSocket::Fast',
    CPLUS         => 11,
    TEST_REQUIRES => {'Test::Exception' => 0, 'Test::Warnings' => 0, 'Test::Fatal' => 0},
    BIN_DEPS      => ['Export::XS', 'URI::XS', 'Encode::Base2N', 'Protocol::HTTP'],
    PKG_CONFIG    => $^O eq 'darwin' ? 'libcrypto' : '',
    LINK          => '-lz -lcrypto',
    SRC           => 'src xs',
    INC           => '-Isrc',
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    CLIB          => {
        DIR          => 'clib',
        CMAKE_TARGET => $cmake_project,
        FILE         => "lib${cmake_project}.a",
    },
    test          => {
        RECURSIVE_TEST_FILES => 1,
        BIN_DEPS             => 'Test::Catch',
        CLIB                 => {
            DIR          => 'clib',
            CMAKE_TARGET => $cmake_tests,
            FILE         => "lib${cmake_tests}.a",
        },
    },
);

write_makefile(%params);

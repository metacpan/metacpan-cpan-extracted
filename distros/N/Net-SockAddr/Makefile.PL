use 5.012;
use Config;
use XS::Install;

my %params = (
    NAME          => 'Net::SockAddr',
    CPLUS         => 11,
    INC           => '-Ilibnet-sockaddr/src -Isrc',
    SRC           => ['src'],
    BIN_DEPS      => ['XS::Framework', 'Export::XS'],
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    TEST_REQUIRES => {'Test::Exception' => 0},
    CLIB          => {
        CMAKE_TARGET => 'net-sockaddr',
        FILE         => 'libnet-sockaddr.a',
        DIR          => 'libnet-sockaddr',
    },
    test          => {
        BIN_DEPS => 'Test::Catch',
        CLIB => {
            CMAKE_TARGET => 'lib-tests',
            FILE => 'liblib-tests.a',
            DIR  => 'libnet-sockaddr',
        },
    },
);

write_makefile(%params);

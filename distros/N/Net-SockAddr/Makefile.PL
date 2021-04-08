use 5.012;
use Config;
use XS::Install;

my $cmake_project = "panda-net-sockaddr";
my $cmake_tests   = "tests";

my %params = (
    NAME          => 'Net::SockAddr',
    CPLUS         => 11,
    INC           => '-Isrc',
    SRC           => 'src',
    BIN_DEPS      => ['XS::Framework', 'Export::XS'],
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    TEST_REQUIRES => {'Test::Exception' => 0},
    CLIB          => {
        DIR          => 'clib',
        CMAKE_TARGET => $cmake_project,
        FILE         => "lib${cmake_project}.a",
    },
    test          => {
        BIN_DEPS => 'Test::Catch',
        CLIB => {
            DIR          => 'clib',
            CMAKE_TARGET => $cmake_tests,
            FILE         => "lib${cmake_tests}.a",
        },
    },
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
);

write_makefile(%params);

use strict;
use XS::Install;

my $cmake_project = "panda-protocol-http";
my $cmake_tests   = "$cmake_project-tests";

my %params = (
    NAME          => 'Protocol::HTTP',
    CPLUS         => 14,
    BIN_DEPS      => ['URI::XS', 'Date', 'Export::XS', 'XS::libboost::mini', 'XS::librangeV3'],
    TEST_REQUIRES => {'Test::More' => 0, 'Test::Fatal' => 0 },
    SRC           => 'src xs',
    INC           => '-Isrc',
    LINK          => '-lz',
    CLIB          => {
        DIR          => 'clib',
        CMAKE_TARGET => $cmake_project,
        FILE         => "lib${cmake_project}.a",
    },
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    test          => {
        SRC                  => 't',
        RECURSIVE_TEST_FILES => 1,
        BIN_DEPS             => 'Test::Catch',
        CLIB                 => {
            DIR          => 'clib',
            CMAKE_TARGET => $cmake_tests,
            CMAKE_OPTIONS => qq{-DPROTOCOL_HTTP_TESTS=ON},
            FILE         => "lib${cmake_tests}.a",
        },
    },
);

write_makefile(%params);

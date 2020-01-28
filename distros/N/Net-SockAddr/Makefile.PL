use 5.012;
use Config;
use XS::Install;

my %params = (
    NAME          => 'Net::SockAddr',
    CPLUS         => 11,
    SRC           => ['src'],
    INC           => '-Isrc',
    BIN_DEPS      => ['XS::Framework', 'Export::XS'],
    CCFLAGS       => '-Wall -Wextra',
    TEST_REQUIRES => {'Test::Exception' => 0},
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    test          => {SRC => 't', BIN_DEPS => 'Test::Catch'},
);

write_makefile(%params);

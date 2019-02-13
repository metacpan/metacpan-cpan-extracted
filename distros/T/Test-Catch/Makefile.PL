use Config;
use XS::Install;

my %params = (
    NAME      => 'Test::Catch',
    BIN_DEPS  => 'CPP::catch',
    BIN_SHARE => {PASSTHROUGH => 'CPP::catch'},
    CPLUS     => 11,
    CCFLAGS   => '-Wall -Wextra',
    test      => {SRC => 't'},
);

write_makefile(%params);


use Config;
use XS::Install;

my %params = (
    NAME      => 'Test::Catch',
    BIN_DEPS  => 'CPP::catch',
    BIN_SHARE => {PASSTHROUGH => 'CPP::catch'},
    CPLUS     => 11,
    CCFLAGS   => '-Wall -Wextra',
    test      => {SRC => 't'},
    OPTIMIZE  => '-O0 -g0', # speedup compilation, tests running performance only slightly affected
    PREREQ_PM => {'Test::More' => '1.302015'},
);

write_makefile(%params);


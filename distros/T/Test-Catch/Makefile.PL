use Config;
use XS::Install;

my %params = (
    NAME      => 'Test::Catch',
    BIN_DEPS  => 'XS::libcatch',
    BIN_SHARE => {PASSTHROUGH => 'XS::libcatch'},
    CPLUS     => 11,
    CCFLAGS   => '-Wall -Wextra',
    test      => {SRC => 't'},
    OPTIMIZE  => '-O0 -g0', # speedup compilation, tests running performance only slightly affected
    PREREQ_PM => {
        'Test::More'   => '1.302015',
        'Test::Simple' => '1.302096', # need $hub->nested
    },
);

write_makefile(%params);


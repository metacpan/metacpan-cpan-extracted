use Config;
use XS::Install;

my %params = (
    NAME      => 'Test::Catch',
    BIN_DEPS  => 'XS::libcatch',
    BIN_SHARE => {PASSTHROUGH => 'XS::libcatch'},
    CPLUS     => 14,
    CCFLAGS   => '-Wall -Wextra',
    test      => {SRC => 't'},
    OPTIMIZE  => '-g0',
    PREREQ_PM => {
        'Test::More'   => '1.302015',
        'Test::Simple' => '1.302096', # need $hub->nested
    },
    MIN_PERL_VERSION => '5.18.0', # older versions have invalid headers for clang c++ 
);

write_makefile(%params);

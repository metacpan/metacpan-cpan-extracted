use strict;
use XS::Install;

write_makefile(
    NAME     => 'Panda::Config::Perl',
    BIN_DEPS => ['XS::Framework', 'Data::Recursive'],
    CCFLAGS  => '-Wall -Wextra',
);

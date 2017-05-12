use strict;
use Panda::Install;

write_makefile(
    NAME          => 'Panda::Config::Perl',
    VERSION_FROM  => 'lib/Panda/Config/Perl.pm',
    ABSTRACT_FROM => 'lib/Panda/Config/Perl.pod',
    BIN_DEPS      => ['Panda::XS', 'Panda::Lib'],
    CCFLAGS       => '-Wall -Wextra',
    #CC            => 'clang++',
);

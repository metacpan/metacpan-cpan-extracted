use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => "Panda::Install",
    VERSION_FROM  => "lib/Panda/Install.pm",
    ABSTRACT_FROM => "lib/Panda/Install.pod",
    TEST_REQUIRES => {'Test::Deep' => 0},
);
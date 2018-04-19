use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => "Panda::Install",
    VERSION_FROM  => "lib/Panda/Install.pm",
    ABSTRACT_FROM => "lib/Panda/Install.pod",
    TEST_REQUIRES => {'Test::Deep' => 0},
    PREREQ_PM     => {'Exporter' => '5.58'},
    CONFIGURE_REQUIRES  => {'ExtUtils::MakeMaker' => 6.64},
    MIN_PERL_VERSION    => '5.10.0',
);
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'MojoX::Logite',
    VERSION_FROM   => 'lib/MojoX/Logite.pm',
    ABSTRACT_FROM  => 'lib/MojoX/Logite.pm',
    AUTHOR         => 'Alberto Attilio Reggiori <areggiori@cpan.org>',
    PL_FILES       => {},
    PREREQ_PM      => {
        'Mojolicious'  => '1.0',
        'ORLite'       => '1.47',
        'Test::More'   => 0
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'MojoX-Logite-*'},
    test  => {TESTS    => 't/*.t t/*/*.t'}
);

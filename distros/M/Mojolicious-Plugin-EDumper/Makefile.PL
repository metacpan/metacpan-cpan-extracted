use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::EDumper',
    AUTHOR           => q{Mikhail Che <mche@cpan.org>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/EDumper.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/EDumper.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
        'Mojolicious'=>5.01,
        #'Data::Recursive::Encode'=>0.01,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #clean => { FILES => 'Mojolicious-Plugin-EDumper-*' },
);

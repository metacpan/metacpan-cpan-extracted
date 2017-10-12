use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Monitoring::GLPlugin',
    AUTHOR           => q{Gerhard Lausser <gerhard.lausser@consol.de>},
    VERSION_FROM     => 'lib/Monitoring/GLPlugin.pm',
    ABSTRACT_FROM    => 'lib/Monitoring/GLPlugin.pm',
    LICENSE          => 'artistic_2',
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
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'GLPlugin-*' },
    META_MERGE => {
        "meta-spec" => {version => 2},
        resources   => {
            repository => {
                type => 'git',
                url => 'https://github.com/lausser/GLPlugin.git',
                web => 'https://github.com/lausser/GLPlugin',
            },
        },
    },

);

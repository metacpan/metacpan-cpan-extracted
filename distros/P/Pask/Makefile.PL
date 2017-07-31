use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Pask',
    AUTHOR           => q{chongwish <chongwish@gmail.com>},
    VERSION_FROM     => 'lib/Pask.pm',
    ABSTRACT_FROM    => 'lib/Pask.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        "Config::General" => "0",
        "Config:INI:Reader" => "0",
        "File::Find::Rule" => "0"
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Pask-*' },
);

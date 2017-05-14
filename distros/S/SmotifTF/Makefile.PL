use 5.8.8;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'SmotifTF',
    AUTHOR           => q{Fiserlab Members  <andras@fiserlab.org>},
    VERSION_FROM     => 'lib/SmotifTF.pm',
    ABSTRACT_FROM    => 'lib/SmotifTF.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.8.8,
    META_ADD => {
        provides => {
            'SmotifTF' => {
                file    => 'lib/SmotifTF.pm',
                 # version => '0.06',
            },  
        },  
    },  
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 2.04,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
        'DBI'              => 1.6,
        'Config::Simple'   => 4.58,
        'Carp'             => 1.04,
        'Math::Trig'       => 1.03,
        'Storable'         => 2.15,
        'IO::Uncompress::Gunzip' => 2.021,
        'Proc::Simple' => 1.26,
        #'Try::Tiny'    => 0.22,
        'Try::Tiny'    => 0.19,
        'File::Find::Rule' => '0.33',
        #'Text::Template'   => 1.46,
        #'Schedule::DRMAAc' => 0.81,


        #'use File::Basename;
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SmotifTF-*' },
);

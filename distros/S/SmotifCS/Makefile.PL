use 5.10.1 ;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'SmotifCS',
    AUTHOR           => q{Fiserlab Members  <andras@fiserlab.org>},
    VERSION_FROM     => 'lib/SmotifCS.pm',
    ABSTRACT         => 'SMOTIFCS implement a Hybrid protein modeling algorithm.',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    EXE_FILES     =>  ['smotifcs_config.ini', 'smotifcs.pl'],
    INSTALLSCRIPT    =>  "$ENV{HOME}/bin",
    MIN_PERL_VERSION => 5.10.1 ,
    META_ADD => {
        provides => {
            'SmotifCS' => {
                file    => 'lib/SmotifCS.pm',
                version => '0.07',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        # 'ExtUtils::MakeMaker' => 0,
        #'ExtUtils::MakeMaker' => 2.04,
        'ExtUtils::MakeMaker' => 7.04,
    },
    BUILD_REQUIRES => {
        'Test::More'  => 1.001002,
        'Test::Pod'   => 1.00,
    },
    PREREQ_PM => {
        'DBI'                    => 1.6,
        'Config::Simple'         => 4.58,
        'Carp'                   => 1.32,
        'Math::Trig'             => 1.2,  
        'Storable'               => 2.20,  
        'IO::Uncompress::Gunzip' => 2.021,
        'Parallel::ForkManager'  => 1.03,
        'File::Spec::Functions'  => 3.40,
        'File::Find::Rule'       => 0.33,
    #   'Try::Tiny'          => 0.19,
    #   'Text::Template'     => 1.46,
    #   'Schedule::DRMAAc'   => 0.81

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SmotifCS-*' },
);

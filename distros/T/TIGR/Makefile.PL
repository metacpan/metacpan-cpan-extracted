use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'TIGR',
    AUTHOR           => q{Joshua Orvis <jorvis@gmail.com>},
    VERSION_FROM     => 'lib/TIGR/HmmTools.pm',
    ABSTRACT    => 'Legacy classes/scripts from TIGR for HMM and FASTA parsing',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '1',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'TIGR-*' },
    EXE_FILES => [qw(script/convert_hmmscan_to_htab.pl)],
    # http://www.dagolden.com/index.php/2419/how-to-add-provides-metadata-via-makefile-pl/
    META_ADD => {
        provides => {
            'TIGR' => {
                file => 'Provides.pm.PL',
                version => '0.03',
            },
        },
    },
);

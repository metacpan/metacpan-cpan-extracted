use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PowerBuilder::DataWindow',
    AUTHOR           => q{Sébastien Kirche <sebastien.kirche@free.fr>},
    VERSION_FROM     => 'lib/PowerBuilder/DataWindow.pm',
    ABSTRACT_FROM    => 'lib/PowerBuilder/DataWindow.pm',
    LICENSE          => 'mit',
    PL_FILES         => {},
    EXE_FILES        => [ 'bin/datawindow_test.pl' ],
    MIN_PERL_VERSION => 5.10.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
		'MarpaX::Languages::PowerBuilder' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PowerBuilder-DataWindow-*' },
);

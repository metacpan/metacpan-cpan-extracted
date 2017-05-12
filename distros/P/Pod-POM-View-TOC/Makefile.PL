use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Pod::POM::View::TOC',
    AUTHOR              => 'Moritz Onken <onken@houseofdesign.de>',
    VERSION_FROM        => 'lib/Pod/POM/View/TOC.pm',
    ABSTRACT_FROM       => 'lib/Pod/POM/View/TOC.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Pod::POM' => "0.17"
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Pod-POM-View-TOC-*' },
);

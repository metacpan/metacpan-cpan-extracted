use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.008001;

WriteMakefile(
    NAME                => 'NLP::GATE',
    AUTHOR              => 'Johann Petrak <firstname.lastname-at-jpetrak-dot-com>',
    VERSION_FROM        => 'lib/NLP/GATE.pm',
    ABSTRACT_FROM       => 'lib/NLP/GATE.pm',
    # MIN_PERL_VERSION => '5.008001',
    NO_META             => 0,
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => '0.92',
        'File::Temp'  => '0.18',
        'FindBin'     => 0,
        #'Tree::RB'   => 0,
        'XML::Writer' => '0.605',
        'XML::LibXML' => '1.69',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'NLP-GATE-*' },
);

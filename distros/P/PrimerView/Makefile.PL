use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PRIMERVIEW',
    AUTHOR           => q{Damien OHalloran <damienoh@gwu.edu>},
    VERSION_FROM     => 'lib/PRIMERVIEW.pm',
    ABSTRACT    => 'generates graphical outputs that map the position and distribution of primers to the target sequence',
    LICENSE          => 'gpl_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Bio::Graphics' => 0,
        'Bio::SeqFeature::Generic' => 0, 
        'Bio::Tools::Run::Alignment::Muscle' => 0,  
        'Bio::AlignIO' => 0,  
        'Bio::Align::Graphics' => 0,
        'Bio::SeqIO' => 0,  
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PRIMERVIEW-*' },
);

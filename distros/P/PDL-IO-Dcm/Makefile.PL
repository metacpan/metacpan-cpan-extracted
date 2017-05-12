use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PDL::IO::Dcm',
    AUTHOR           => q{Albrecht Ingo Schmid <ingosch@gmx.at>},
    VERSION_FROM     => 'lib/PDL/IO/Dcm.pm',
    ABSTRACT_FROM    => 'lib/PDL/IO/Dcm.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES		=>{},
    EXE_FILES         => ['bin/read_dcm.pl'],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'PDL'=>0,
	'List::MoreUtils'=>0,
	'DicomPack::IO::DicomReader'=>0,
	'DicomPack::DB::DicomTagDict'=>0,
	'DicomPack::DB::DicomVRDict'=>0,
	#'PDL::IO::Nifti'=>0,
	'PDL::IO::Sereal'=>0,
	'Getopt::Tabular'=>0,
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PDL-IO-Dcm-*' },
);

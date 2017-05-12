use strict;
use warnings;
use ExtUtils::MakeMaker;
use inc::ExtUtils::MY_Metafile;

my_metafile 'Sub::ScopeFinalizer' => {
	license => 'perl',
	requires => {
	},
	build_requires => {
		'Test::More'      => 0,
	},
};

WriteMakefile(
    NAME                => 'Sub::ScopeFinalizer',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/Sub/ScopeFinalizer.pm',
    ABSTRACT_FROM       => 'lib/Sub/ScopeFinalizer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sub-ScopeFinalizer-*' },
);

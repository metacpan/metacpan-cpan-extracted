use strict;
use 5.006;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'NCBIx::BigFetch',
    AUTHOR              => 'Roger A Hall <roger@iosea.com>',
    ABSTRACT            => 'Robustly manage very large text query results from NCBI eUtils',
    VERSION_FROM        => 'lib/NCBIx/BigFetch.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'version'           => 0,
    	'LWP::Simple'       => 1.41, 
    	'YAML'              => 0.65, 
    	'Time::HiRes'       => 1.9715, 
	'Class::Std'        => 0.0.9, 
	'Class::Std::Utils' => 0.0.3,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'NCBIx-BigFetch-*' },
);

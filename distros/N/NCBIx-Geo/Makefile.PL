use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'NCBIx::Geo',
    AUTHOR              => 'Roger A Hall <rogerhall@cpan.org>',
    ABSTRACT            => 'Download and Compare Transcripts through NCBI GEO',
    VERSION_FROM        => 'lib/NCBIx/Geo.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'version'           => 0,
        'Class::Std'        => 0.0.9,
        'Class::Std::Utils' => 0.0.3,
        'LWP::Simple'       => 1.41,
        'XML::Simple'       => 0,
        'Data::Dumper'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'NCBIx-Geo-*' },
);

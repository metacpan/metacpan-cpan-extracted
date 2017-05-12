require 5.008008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TVDB::API',
    AUTHOR              => 'Behan Webster <behanw@websterwood.com>',
    VERSION_FROM        => 'lib/TVDB/API.pm',
    ABSTRACT_FROM       => 'lib/TVDB/API.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Compress::Zlib' => 0,
        'DBM::Deep' => 0,
        'Debug::Simple' => 0,
        'IO::Uncompress::Unzip' => 0,
        'LWP' => 0,
        'XML::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TVDB-API-*' },
);

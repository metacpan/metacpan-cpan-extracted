use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PDF::TextBlock',
    AUTHOR              => 'Jay Hannah <jay@jays.net>',
    VERSION_FROM        => 'lib/PDF/TextBlock.pm',
    ABSTRACT_FROM       => 'lib/PDF/TextBlock.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'PDF::API2'             => 0,
        'Class::Accessor::Fast' => 0,
        'File::Temp'            => 0,
    },
    META_MERGE => {
         resources => {
             repository  =>  'https://github.com/jhannah/pdf-textblock',
         },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PDF-TextBlock-*' },
);

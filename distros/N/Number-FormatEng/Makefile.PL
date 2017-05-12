use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Number::FormatEng',
    AUTHOR              => 'Gene Sullivan <gsullivan@cpan.org>',
    VERSION_FROM        => 'lib/Number/FormatEng.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/convert_eng' ],
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean               => { FILES => 'Number-FormatEng-*' },
);

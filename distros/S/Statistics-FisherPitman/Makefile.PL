use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::FisherPitman',
    AUTHOR              => 'Roderick Garton <rgarton@cpan.org>',
    VERSION_FROM        => 'lib/Statistics/FisherPitman.pm',
    ABSTRACT_FROM       => 'lib/Statistics/FisherPitman.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'List::Util' => 1.18,
        'Statistics::Descriptive' => 2.6,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-FisherPitman-0.034-*' },
);

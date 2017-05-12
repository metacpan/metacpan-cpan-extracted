use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SVN::Notify::Filter::EmailFlatFileDB',
    AUTHOR              => 'Jeffrey Borlik <jborlik@earthlink.net>',
    VERSION_FROM        => 'lib/SVN/Notify/Filter/EmailFlatFileDB.pm',
    ABSTRACT_FROM       => 'lib/SVN/Notify/Filter/EmailFlatFileDB.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => 0,
        'SVN::Notify' => '2.72',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SVN-Notify-Filter-EmailFlatFileDB-*' },
);

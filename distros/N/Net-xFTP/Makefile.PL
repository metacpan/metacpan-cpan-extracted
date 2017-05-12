use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::xFTP',
    AUTHOR              => 'Jim Turner <turnerjw784@yahoo.com>',
    VERSION_FROM        => 'lib/Net/xFTP.pm',
    ABSTRACT_FROM       => 'lib/Net/xFTP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-xFTP-*' },
);

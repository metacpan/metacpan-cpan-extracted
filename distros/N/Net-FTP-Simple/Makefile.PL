use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::FTP::Simple',
    AUTHOR              => 'Wil Cooley <wcooley@nakedape.cc>',
    VERSION_FROM        => 'lib/Net/FTP/Simple.pm',
    ABSTRACT_FROM       => 'lib/Net/FTP/Simple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Net::FTP'              => 0,
        'Test::More'            => 0,
        'Test::MockObject'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-FTP-Simple-*' },
);

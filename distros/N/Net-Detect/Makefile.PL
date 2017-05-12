use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Net::Detect',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Net/Detect.pm',
    ABSTRACT_FROM => 'lib/Net/Detect.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
        'Net::Ping'  => 2.41,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Net-Detect-*' },
);

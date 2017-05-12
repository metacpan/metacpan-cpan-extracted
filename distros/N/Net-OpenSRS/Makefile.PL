use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Net::OpenSRS',
    AUTHOR        => 'Richard L. Siddall <opensrs@elirion.net>', # Really just maintainer
    VERSION_FROM  => 'lib/Net/OpenSRS.pm',
    ABSTRACT_FROM => 'lib/Net/OpenSRS.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'     => 0,
        'LWP::UserAgent' => 0,
        'XML::Simple'    => 0,
        'Digest::MD5'    => 0,
        'Date::Calc'     => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Net-OpenSRS-*' },
);

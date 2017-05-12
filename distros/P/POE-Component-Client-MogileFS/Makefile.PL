use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Component::Client::MogileFS',
    AUTHOR              => 'mock <mock@obscurity.org>',
    VERSION_FROM        => 'lib/POE/Component/Client/MogileFS.pm',
    ABSTRACT_FROM       => 'lib/POE/Component/Client/MogileFS.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'MogileFS::Client' => 0,
        'POE' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Component-Client-MogileFS-*' },
);

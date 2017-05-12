use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Component::Client::opentick',
    AUTHOR              => 'Jason McManus (INFIDEL) <infidel@cpan.org>',
    VERSION_FROM        => 'lib/POE/Component/Client/opentick.pm',
    ABSTRACT_FROM       => 'lib/POE/Component/Client/opentick.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Time::HiRes'       => 0,
        'Test::More'        => 0,
        'POE'               => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Component-Client-opentick-*' },
);

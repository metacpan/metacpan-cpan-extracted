use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::HTTPS::Any',
    AUTHOR              => 'Ivan Kohler <ivan-net-https-any@freeside.biz>',
    VERSION_FROM        => 'lib/Net/HTTPS/Any.pm',
    ABSTRACT_FROM       => 'lib/Net/HTTPS/Any.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => 0,
        'URI::Escape' => 0,
        'Tie::IxHash' => 0,
        # If you are aware of a way to declare an OR relation in prerequisites,
        # please tell me, you would be my hero.  it doesn't have to be EU:MM.
        # 'Net::SSLeay' => 0,
        # or 'Crypt::SSLeay' => 0,
        #    'LWP' => 0,

        #failing tests is worse, Net::SSLeay appears to finally have emerged
        # as best-practice with the release of LWP::Protocol::https that uses
        # IO::Socket::SSL and therefore Net::SSLeay
        'Net::SSLeay' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-HTTPS-Any-*' },
);

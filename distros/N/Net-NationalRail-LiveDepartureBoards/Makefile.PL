use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::NationalRail::LiveDepartureBoards',
    AUTHOR              => 'Tim Retout <diocles@cpan.org>',
    VERSION_FROM        => 'lib/Net/NationalRail/LiveDepartureBoards.pm',
    ABSTRACT_FROM       => 'lib/Net/NationalRail/LiveDepartureBoards.pm',
    PL_FILES            => {},
    LICENSE		=> 'perl',
    PREREQ_PM => {
        'Test::More' => 0,
	'SOAP::Lite' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-NationalRail-LiveDepartureBoards-*' },
);

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::ILO',
    AUTHOR              => 'Nicholas Lewis <nick.lewis@gmail.com>',
    VERSION_FROM        => 'lib/Net/ILO.pm',
    ABSTRACT_FROM       => 'lib/Net/ILO.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		'IO::Socket::SSL' 	=> 0,
        'Test::More' 		=> 0,
		'XML::Simple' 		=> 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-ILO-*' },
);

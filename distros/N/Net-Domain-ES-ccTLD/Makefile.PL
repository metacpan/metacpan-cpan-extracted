use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Domain::ES::ccTLD',
    AUTHOR              => q{David Moreno <david@axiombox.com>},
    VERSION_FROM        => 'lib/Net/Domain/ES/ccTLD.pm',
    ABSTRACT_FROM       => 'lib/Net/Domain/ES/ccTLD.pm',
	LICENSE				=> 'mit',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Modern::Perl' => '1.03',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Domain-ES-ccTLD-*' },
);

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'POE::Component::RSSAggregator',
    AUTHOR        => 'Jeff Bisbee <jbisbee@cpan.org>',
    VERSION_FROM  => 'lib/POE/Component/RSSAggregator.pm',
    ABSTRACT_FROM => 'lib/POE/Component/RSSAggregator.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'POE'                          => 0,
        'POE::Component::Client::HTTP' => 0.51,
        'POE::Component::Client::DNS'  => 0.98,
        'XML::RSS::Feed'               => 0.01,
        'HTTP::Request'                => 1.30,
        'Test::More'                   => 0,
        'Carp'                         => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean   => { FILES => 'POE-Component-RSSAggregator-*' },
    LICENSE => 'perl',
);

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'POE::Component::AtomAggregator',
    AUTHOR        => 'Jeff Bisbee <jbisbee@cpan.org>',
    VERSION_FROM  => 'lib/POE/Component/AtomAggregator.pm',
    ABSTRACT_FROM => 'lib/POE/Component/AtomAggregator.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'POE::Component::Client::HTTP' => 0.51,
        'POE::Component::Client::DNS'  => 0.98,
        'XML::Atom'                    => undef,
        'HTTP::Request'                => 1.30,
        'Test::More'                   => 0,
        'Carp'                         => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean   => { FILES => 'POE-Component-AtomAggregator-*' },
#    LICENSE => 'perl',
);

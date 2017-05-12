use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR        => 'Scott Lanning <slanning@cpan.org>',
    NAME          => 'Net::Graphite',
    VERSION_FROM  => 'lib/Net/Graphite.pm',
    PREREQ_PM     => {
        # not sure 
        'IO::Socket::INET' => 0,  # perl v5.6.0
        'Scalar::Util'     => 0,  # perl v5.7.3
    },
);

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Monit::HTTP',
    AUTHOR              => 'Angelo "pallotron" Failla <pallotron@freaknet.org>',
    VERSION_FROM        => 'lib/Monit/HTTP.pm',
    ABSTRACT_FROM       => 'lib/Monit/HTTP.pm',
    EXE_FILES           => [qw( mm )],
    PL_FILES            => { },
    PREREQ_PM => {
        'LWP::UserAgent' => 0, 
        'HTTP::Request' => 0,
        'Test::More' => 0,
        'Test::MockModule' => 0,
        'XML::Bare' => 0,
        'YAML' => 0,
        'Error' => 0,
        'Test::Pod::Coverage' => 1.08,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Monit-HTTP-*' },
);

use strict;
use warnings;
use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'QualysGuard::Request',
    AUTHOR              => 'Patrick Devlin <pdevlin@cpan.org>',
    VERSION_FROM        => 'lib/QualysGuard/Request.pm',
    ABSTRACT_FROM       => 'lib/QualysGuard/Request.pm',
    PL_FILES            => {},
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More'        => 0.78,
        'LWP::UserAgent'    => 2.036,
        'URI::Escape'       => 3.28,
        'HTTP::Request'     => 1.40,
        'Carp'              => 1.04,
        'XML::XPath'        => 1.13,
        'XML::Simple'       => 2.18,
        'Net::SSL'          => 2.84,
        'Net::IP'           => 1.25,
        'IO::File'          => 1.13,
        'Scalar::Util'      => 1.19,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'QualysGuard::Request-*' },
);

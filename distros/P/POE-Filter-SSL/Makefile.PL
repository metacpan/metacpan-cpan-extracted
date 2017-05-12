use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Filter::SSL',
    AUTHOR              => 'Markus Schraeder <privi@cpan.org>',
    VERSION_FROM        => 'lib/POE/Filter/SSL.pm',
    ABSTRACT_FROM       => 'lib/POE/Filter/SSL.pm',
    PL_FILES            => {},
    LIBS		=> '-lssl -lcrypto -ldl',
    #TYPEMAPS		=> ['./typemap'],
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::SSLeay'   => '1.32',
        'POE::Filter::Stackable' => 0,
        'POE::Filter::HTTPD' => 0,
        'POE::Wheel::ReadWrite' => 0,
        'XSLoader'      => 0,
        'HTTP::Status'   => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Filter-SSL-*' },
);

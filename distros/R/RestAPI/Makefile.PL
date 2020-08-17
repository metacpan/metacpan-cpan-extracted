use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RestAPI',
    AUTHOR           => q{Marco Masetti <marco.masetti@sky.uk>},
    VERSION_FROM     => 'lib/RestAPI.pm',
    ABSTRACT_FROM    => 'lib/RestAPI.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    EXE_FILES        => [ qw(scripts/rest-client.pl) ],
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Encode'            => "3.06",
        'Getopt::Long'      => "2.51",
        'JSON::XS'          => "4.02",
        'Log::Log4perl'     => "1.50",
        'LWP::UserAgent'    => "5.46",
        'LWP::ConsoleLogger::Everywhere' => "0.000042",
        'Moo'               => "2.004000",
        'XML::Simple'       => "2.25",
        'Time::HiRes'       => "1.9721",
        'Types::Standard'   => "1.010002",
        'namespace::autoclean' => "0.29",
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RestAPI-*' },
);

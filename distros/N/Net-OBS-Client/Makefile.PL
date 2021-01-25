use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::OBS::Client',
    AUTHOR           => q{Frank Schreiner <frank@samaxi.de>},
    VERSION_FROM     => 'lib/Net/OBS/Client.pm',
    ABSTRACT_FROM    => 'lib/Net/OBS/Client.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'XML::Parser' => 0,
        'Test::HTTP::MockServer' => 0,
    },
    PREREQ_PM => {
        'Moose'               =>  0,
        'Moose::Role'         =>  0,
        'LWP::UserAgent'      =>  0,
        'XML::Structured'     =>  0,
        'Config::INI::Reader' =>  0,
        'Config::Tiny'        =>  0,
        'HTTP::Request'       =>  0,
        'HTTP::Cookies'       =>  0,
        'URI::URL'            =>  0,
        'Path::Class'         =>  0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-OBS-Client-*' },
);

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Params::Check::Item',
    AUTHOR           => q{Samuel Steffl <sam@ssteffl.com>},
    VERSION_FROM     => 'lib/Params/Check/Item.pm',
    ABSTRACT_FROM    => 'lib/Params/Check/Item.pm',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'Test::Exception' => '0',
        'Test::Pod' => '0',
        'Test::Pod::Coverage' => '0',
        'Test::CheckManifest' => '0',
    },
    PREREQ_PM => {
        'Carp::Assert' => '0',
        'Scalar::Util' => '0'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Params-Check-Item-*' },
);

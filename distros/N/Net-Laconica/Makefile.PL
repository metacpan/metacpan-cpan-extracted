use 5.008000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Laconica',
    AUTHOR              => 'Alan Haggai Alavi <alanhaggai@alanhaggai.org>',
    VERSION_FROM        => 'lib/Net/Laconica.pm',
    ABSTRACT_FROM       => 'lib/Net/Laconica.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'          => 0,
        'Test::Warn'          => 0,
        'Test::Exception'     => 0,
        'HTML::Parser'        => 3.56,
        'LWP::UserAgent'      => 0,
        'Data::Validate'      => 0,
        'Data::Validate::URI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Laconica-*' },
    LICENSE             => 'perl',
);

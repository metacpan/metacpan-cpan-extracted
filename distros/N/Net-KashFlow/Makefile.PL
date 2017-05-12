use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::KashFlow',
    AUTHOR              => q{Simon Cozens <simon@simon-cozens.org>},
    VERSION_FROM        => 'lib/Net/KashFlow.pm',
    ABSTRACT_FROM       => 'lib/Net/KashFlow.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'SOAP::Lite' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-KashFlow-*' },
);

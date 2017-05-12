use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'PagSeguro::Status',
    AUTHOR =>
      q{Daniel de Oliveira Mantovani <daniel.oliveira.mantovani@gmail.com>},
    VERSION_FROM  => 'lib/PagSeguro/Status.pm',
    ABSTRACT_FROM => 'lib/PagSeguro/Status.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'           => 0,
        'Moose'                => 0,
        'WWW::Mechanize'       => 0,
        'LWP::Protocol::https' => 0,
        'DateTime' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'PagSeguro-Status-*' },
);

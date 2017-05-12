use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::RFC::Search',
    AUTHOR           => q{Nikolay Aviltsev <navi@cpan.org>},
    VERSION_FROM     => 'lib/Net/RFC/Search.pm',
    ABSTRACT_FROM    => 'lib/Net/RFC/Search.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'LWP::UserAgent'            => 0,
        'IO::File'                  => 0,
        'File::Tempdir'             => 0,
        'Carp'                      => 0,
        'File::HomeDir'                       => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-RFC-Search-*' },
);

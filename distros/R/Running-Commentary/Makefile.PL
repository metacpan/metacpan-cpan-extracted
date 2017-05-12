use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Running::Commentary',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Running/Commentary.pm',
    ABSTRACT_FROM       => 'lib/Running/Commentary.pm',
    PL_FILES            => {},
    LICENSE             => 'perl',
    MIN_PERL_VERSION    => 5.014,
    PREREQ_PM => {
        'Lexical::Failure' => 0,
        'Keyword::Simple'  => 0,
        'Scalar::Util'     => 0,
        'List::Util'       => 0,
        'Data::Dumper'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Running-Commentary-*' },
);


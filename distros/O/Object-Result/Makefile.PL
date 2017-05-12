use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Object::Result',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Object/Result.pm',
    ABSTRACT_FROM       => 'lib/Object/Result.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.014,
    PREREQ_PM => {
        'Test::More'         => 0,
        'Keyword::Simple'    => 0,
        'PPI'                => 0,
        'Method::Signatures' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Object-Result-*' },
);

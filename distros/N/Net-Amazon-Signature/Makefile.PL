use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Amazon::Signature',
    AUTHOR              => 'Rachel Richard <rachel@nmcfarl.org>',
    VERSION_FROM        => 'lib/Net/Amazon/Signature.pm',
    ABSTRACT            => 'Makes secret signature for certain web services on Amazon',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Amazon-Signature-*' },
);

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Regexp::Grammars',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/Regexp/Grammars.pm',
    ABSTRACT_FROM       => 'lib/Regexp/Grammars.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
            'Test::More'    => 0,
            'version'       => 0,
        ($] >= 5.018 ? (
            'B::Hooks::Parser' => 0.16,
        ) : ())
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Regexp-Grammars-*' },
);

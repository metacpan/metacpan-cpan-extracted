use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Term::Emit',
    AUTHOR              => 'Steve Roscio <roscio@cpan.org>',
    VERSION_FROM        => 'lib/Term/Emit.pm',
    ABSTRACT_FROM       => 'lib/Term/Emit.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Scope::Upper'  => '0.06',
        'Test::More'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Term-Emit-*' },
);

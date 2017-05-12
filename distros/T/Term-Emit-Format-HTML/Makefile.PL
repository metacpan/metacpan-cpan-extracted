use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Term::Emit::Format::HTML',
    AUTHOR              => 'Steve Roscio <roscio@cpan.org>',
    VERSION_FROM        => 'lib/Term/Emit/Format/HTML.pm',
    ABSTRACT_FROM       => 'lib/Term/Emit/Format/HTML.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Term-Emit-Format-HTML-*' },
);

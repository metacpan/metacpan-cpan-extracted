use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'Syntax::Highlight::HTML',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Syntax/Highlight/HTML.pm',
    ABSTRACT_FROM       => 'lib/Syntax/Highlight/HTML.pm',
    PREREQ_PM => {
        'HTML::Parser' => 3.00,
        'Test::More' => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Syntax-Highlight-HTML-*' },
);

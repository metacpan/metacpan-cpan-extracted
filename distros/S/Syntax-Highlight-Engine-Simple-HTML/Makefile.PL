use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Syntax::Highlight::Engine::Simple::HTML',
    AUTHOR              => ['Sugama Keita <sugama@jamadam.com>', 'Andreas K. Huettel <mail@akhuettel.de>'],
    LICENSE             => 'perl_5',
    VERSION_FROM        => 'lib/Syntax/Highlight/Engine/Simple/HTML.pm',
    ABSTRACT_FROM       => 'lib/Syntax/Highlight/Engine/Simple/HTML.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Syntax::Highlight::Engine::Simple'    => '0.02',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage => 'https://github.com/akhuettel/Syntax-Highlight-Engine-Simple-HTML',
            repository => {
                type => 'git',
                url => 'git://github.com/akhuettel/Syntax-Highlight-Engine-Simple-HTML',
                web => 'https://github.com/akhuettel/Syntax-Highlight-Engine-Simple-HTML',
            },
            bugtracker => {
                web => 'https://github.com/akhuettel/Syntax-Highlight-Engine-Simple-HTML/issues',
            },
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Syntax-Highlight-Engine-Simple-HTML-*' },
);

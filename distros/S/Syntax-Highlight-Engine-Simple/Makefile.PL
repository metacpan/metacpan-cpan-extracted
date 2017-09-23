use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Syntax::Highlight::Engine::Simple',
    AUTHOR              => ['Sugama Keita <sugama@jamadam.com>', 'Andreas K. Huettel <mail@akhuettel.de>'],
    VERSION_FROM        => 'lib/Syntax/Highlight/Engine/Simple.pm',
    ABSTRACT_FROM       => 'lib/Syntax/Highlight/Engine/Simple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'			=> 0,
        'version'				=> 0,
        'encoding'				=> 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage => 'https://github.com/lab-measurement/Syntax-Highlight-Engine-Simple',
            repository => {
                type => 'git',
                url => 'git://github.com/lab-measurement/Syntax-Highlight-Engine-Simple',
                web => 'https://github.com/lab-measurement/Syntax-Highlight-Engine-Simple',
            },
            bugtracker => {
                web => 'https://github.com/lab-measurement/Syntax-Highlight-Engine-Simple/issues',
            },
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Syntax-Highlight-Engine-Simple-*' },
    LICENSE             => 'perl_5',
);

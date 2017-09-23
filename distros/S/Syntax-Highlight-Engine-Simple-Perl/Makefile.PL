use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Syntax::Highlight::Engine::Simple::Perl',
    AUTHOR              => ['Sugama Keita <sugama@jamadam.com>', 'Andreas K. Huettel <mail@akhuettel.de>'],
    LICENSE             => 'perl_5',
    VERSION_FROM        => 'lib/Syntax/Highlight/Engine/Simple/Perl.pm',
    ABSTRACT_FROM       => 'lib/Syntax/Highlight/Engine/Simple/Perl.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Syntax::Highlight::Engine::Simple'    => '0.02',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage => 'https://github.com/lab-measurement/Syntax-Highlight-Engine-Simple-Perl',
            repository => {
                type => 'git',
                url => 'git://github.com/lab-measurement/Syntax-Highlight-Engine-Simple-Perl',
                web => 'https://github.com/lab-measurement/Syntax-Highlight-Engine-Simple-Perl',
            },
            bugtracker => {
                web => 'https://github.com/lab-measurement/Syntax-Highlight-Engine-Simple-Perl/issues',
            },
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Syntax-Highlight-Engine-Simple-Perl-*' },
);

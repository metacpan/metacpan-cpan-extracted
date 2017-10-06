use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => "Mojolicious::Plugin::Check",
    VERSION_FROM    => "lib/Mojolicious/Plugin/Check.pm",
    ABSTRACT_FROM   => "lib/Mojolicious/Plugin/Check.pm",
    MAKEFILE        => 'Makefile',
    LICENSE         => 'Perl',
    AUTHOR          => [
        'Dmitry E. Oboukhov <unera@debian.org>,',
        'Roman V. Nikolaev <rshadow@rambler.ru>',
    ],
    MIN_PERL_VERSION => '5.10.0',
    PREREQ_PM       => {
        'Mojolicious'                   => '0',
    },
    META_MERGE => {
        resources => {
            homepage =>
                'https://github.com/dr-co/Mojolicious-Plugin-Check',
            repository =>
                'https://github.com/dr-co/Mojolicious-Plugin-Check',
            bugtracker =>
                'https://github.com/dr-co/Mojolicious-Plugin-Check/issues',
        }
   },
);

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => "Mojolicious::Plugin::Vparam",
    VERSION_FROM    => "lib/Mojolicious/Plugin/Vparam.pm",
    ABSTRACT_FROM   => "lib/Mojolicious/Plugin/Vparam.pm",
    MAKEFILE        => 'Makefile',
    LICENSE         => 'Perl',
    AUTHOR          => [
        'Dmitry E. Oboukhov <unera@debian.org>,',
        'Roman V. Nikolaev <rshadow@rambler.ru>',
    ],
    MIN_PERL_VERSION => '5.10.0',
    PREREQ_PM       => {
        'Mojolicious'                   => '0',
        'DateTime'                      => '0',
        'DateTime::Format::DateParse'   => '0',
        'Mail::RFC822::Address'         => '0',
        'XML::LibXML'                   => '0',
        'List::MoreUtils'               => '0',
        'Test::Compile'                 => '0',
        'Test::More'                    => '0',
    },
    META_MERGE => {
        resources => {
            homepage =>
                'https://github.com/dr-co/libmojolicious-plugin-vparam-perl',
            repository =>
                'https://github.com/dr-co/libmojolicious-plugin-vparam-perl',
            bugtracker =>
                'https://github.com/dr-co/libmojolicious-plugin-vparam-perl/issues',
        }
   },
);

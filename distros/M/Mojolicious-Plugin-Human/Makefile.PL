use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => "Mojolicious::Plugin::Human",
    VERSION_FROM    => "lib/Mojolicious/Plugin/Human.pm",
    ABSTRACT_FROM   => "lib/Mojolicious/Plugin/Human.pm",
    MAKEFILE        => 'Makefile',
    LICENSE         => 'Perl',
    AUTHOR          => [
        'Dmitry E. Oboukhov <unera@debian.org>,',
        'Roman V. Nikolaev <rshadow@rambler.ru>',
    ],
    MIN_PERL_VERSION => '5.10.0',
    PREREQ_PM       => {
        'Mojo::Base'                   => '0',
        'DateTime'                     => '0',
        'DateTime::Format::DateParse'  => '0',
    	'Test::Compile'                => '0',
    },
    META_MERGE   => {
        resources => {
          homepage    => 'https://github.com/dr-co/libmojolicious-plugin-human-perl',
          repository  => 'https://github.com/dr-co/libmojolicious-plugin-human-perl',
          bugtracker  => 'https://github.com/dr-co/libmojolicious-plugin-human-perl/issues'
        },
        no_index => {directory => ['t']}
    },
);

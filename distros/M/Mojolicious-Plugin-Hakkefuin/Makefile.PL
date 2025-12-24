use strict;
use warnings;
use 5.020;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME               => 'Mojolicious::Plugin::Hakkefuin',
    AUTHOR             => 'Achmad Yusri Afandi <yusrideb@cpan.org>',
    LICENSE            => 'artistic_2',
    ABSTRACT_FROM      => 'lib/Mojolicious/Plugin/Hakkefuin.pm',
    VERSION_FROM       => 'lib/Mojolicious/Plugin/Hakkefuin.pm',
    MIN_PERL_VERSION   => '5.020',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '7.12', },
    PREREQ_PM          => {
        'Carp'                   => 0,
        'CellBIS::Random'        => 0,
        'CellBIS::SQL::Abstract' => '1.2',
        'Mojo::SQLite'           => 0,
        'Mojolicious'            => 0,
        'String::Random'         => 0,
    },
    TEST_REQUIRES => {
        'Mojolicious::Lite' => 0,
        'Test::Mojo'        => 0,
        'Test::More'        => 0,
        'Mojo::Date'        => 0,
        'Mojo::File'        => 0,
        'Mojo::URL'         => 0,
        'IO::Socket::INET'  => 0,
        'IO::Socket::UNIX'  => 0,
        'Socket'            => 0,
    },
    META_MERGE => {
        'meta-spec'    => { version => 2 },
        dynamic_config => 0,
        resources      => {
            homepage   => 'https://github.com/CellBIS/mojo-hakkefuin',
            repository => {
                type => 'git',
                url  => 'https://github.com/CellBIS/mojo-hakkefuin.git',
                web  => 'https://github.com/CellBIS/mojo-hakkefuin',
            },
            bugtracker =>
              { web => 'https://github.com/CellBIS/mojo-hakkefuin/issues', },
        },
        no_index          => { directory => [qw(t test example inc)] },
        optional_features => {
            mariadb => {
                description => 'MariaDB/MySQL backend support',
                prereqs => { runtime => { requires => { 'Mojo::mysql' => 0 } } }
            },
            pg => {
                description => 'PostgreSQL backend support',
                prereqs => { runtime => { requires => { 'Mojo::Pg' => 0 } } }
            },
        },
    },
    test => {
        TESTS => 't/*.t t/backend/*.t t/mojolicious/*.t t/mojolicious/lite/*.t'
    },
);

WriteMakefile(%WriteMakefileArgs);

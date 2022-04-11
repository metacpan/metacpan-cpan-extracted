use ExtUtils::MakeMaker;

use 5.008001;

WriteMakefile(
    NAME             => 'Perl::Server',
    ABSTRACT         => 'A simple Perl server launcher',
    AUTHOR           => 'Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>',
    VERSION_FROM     => 'lib/Perl/Server.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.008001',
    
    EXE_FILES => [
      "script/perl-server"
    ],    
    
    META_MERGE => {
        'meta-spec' => {
          version => 2,
        },

        resources => {
            homepage => 'https://github.com/ltmbr/Perl-Server',

            bugtracker => {
                web => 'https://github.com/ltmbr/Perl-Server/issues'
            },

            repository => {
                type => 'git',
                url  => 'git@github.com:ltmbr/Perl-Server.git',
                web  => 'https://github.com/ltmbr/Perl-Server'
            }
        }
    },

    PREREQ_PM => {
        'Cwd'             => 0,
        'Plack'           => 0,
        'Plack::App::WWW' => '0.03',
        'Term::ANSIColor' => 0,
        'Net::EmptyPort'  => 0
    },
    
    TEST_REQUIRES => {
        'Test::More'     => 0,
        'Test::Requires' => 0
    },   

    test => {
        TESTS => 't/*.t'
    }
);

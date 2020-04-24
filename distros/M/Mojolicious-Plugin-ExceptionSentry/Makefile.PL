use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::ExceptionSentry',
    ABSTRACT         => 'Sentry Plugin for Mojolicious - Mojolicious::Plugin::ExceptionSentry',
    AUTHOR           => 'Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>',
    VERSION_FROM     => 'lib/Mojolicious/Plugin/ExceptionSentry.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010001',
    
    META_MERGE => {
        'meta-spec' => {
          version => 2,
        },
     
        resources => {
            homepage => 'https://github.com/lucas1/Mojolicious-Plugin-ExceptionSentry',
       
            bugtracker => {
                web => 'https://github.com/lucas1/Mojolicious-Plugin-ExceptionSentry/issues'
            },
       
            repository => {
                type => 'git',
                url  => 'git@github.com:lucas1/Mojolicious-Plugin-ExceptionSentry.git',
                web  => 'https://github.com/lucas1/Mojolicious-Plugin-ExceptionSentry'
            }
        }        
    },
    
    PREREQ_PM => {
        'Mojolicious'   => 0,
        'Mojo::Base'    => 0,
        'Sentry::Raven' => 0
    },

    TEST_REQUIRES => {
        'Test::More'        => 0,
        'Mojolicious'       => 0,
        'Test::Fake::HTTPD' => 0
    },
    
    test => {
        TESTS => 't/*.t'
    }    
);

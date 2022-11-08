use ExtUtils::MakeMaker;

use 5.008001;

WriteMakefile(
    NAME             => 'SQL::Load',
    ABSTRACT         => 'This module is a simple SQL file loader',
    AUTHOR           => 'Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>',
    VERSION_FROM     => 'lib/SQL/Load.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.008001', 
    
    META_MERGE => {
        'meta-spec' => {
          version => 2,
        },

        resources => {
            homepage => 'https://github.com/ltmbr/SQL-Load',

            bugtracker => {
                web => 'https://github.com/ltmbr/SQL-Load/issues'
            },

            repository => {
                type => 'git',
                url  => 'git@github.com:ltmbr/SQL-Load.git',
                web  => 'https://github.com/ltmbr/SQL-Load'
            }
        }
    },

    PREREQ_PM => {
        'base'              => 0,
        'Carp'              => 0,
        'Exporter'          => 0,
        'String::CamelCase' => '0.04'
    },
    
    TEST_REQUIRES => {
        'Test::More' => 0,
        'File::Temp' => 0
    },   

    test => {
        TESTS => 't/*.t'
    }
);

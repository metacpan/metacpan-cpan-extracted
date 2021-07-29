use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::Route',
    ABSTRACT         => 'Plugin to loader files of routes',
    AUTHOR           => 'Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>',
    VERSION_FROM     => 'lib/Mojolicious/Plugin/Route.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.008001',

    META_MERGE => {
        'meta-spec' => {
          version => 2,
        },

        resources => {
            homepage => 'https://github.com/ltmbr/Mojolicious-Plugin-Route',

            bugtracker => {
                web => 'https://github.com/ltmbr/Mojolicious-Plugin-Route/issues'
            },

            repository => {
                type => 'git',
                url  => 'git@github.com:ltmbr/Mojolicious-Plugin-Route.git',
                web  => 'https://github.com/ltmbr/Mojolicious-Plugin-Route'
            }
        }
    },

    PREREQ_PM => {
        'Mojolicious' => '6.0',
        'Carp' => 0,
        'constant' => 0,
        'Scalar::Util' => 0
    },

    test => {
        TESTS => 't/*.t'
    }
);

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Plack::App::WWW',
    ABSTRACT         => 'Serve cgi-bin and static files from root directory',
    AUTHOR           => 'Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>',
    VERSION_FROM     => 'lib/Plack/App/WWW.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.008001',

    META_MERGE => {
        'meta-spec' => {
          version => 2,
        },

        resources => {
            homepage => 'https://github.com/ltmbr/Plack-App-WWW',

            bugtracker => {
                web => 'https://github.com/ltmbr/Plack-App-WWW/issues'
            },

            repository => {
                type => 'git',
                url  => 'git@github.com:ltmbr/Plack-App-WWW.git',
                web  => 'https://github.com/ltmbr/Plack-App-WWW'
            }
        }
    },

    PREREQ_PM => {
        'Plack' => 0,
        'CGI::Compile' => 0,
        'CGI::Emulate::PSGI' => 0
    },

    test => {
        TESTS => 't/*.t'
    }
);

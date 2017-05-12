use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Salvation::AnyNotify::Plugin::Server',
    VERSION_FROM => 'lib/Salvation/AnyNotify/Plugin/Server.pm',
    ABSTRACT => 'Server plugin for Salvation::AnyNotify',
    AUTHOR => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
    LICENSE => 'mit',
    PREREQ_PM => {
        'Salvation::TC' => '0.11',
        'Salvation::Method::Signatures' => '0.02',
        'Salvation::DaemonDecl' => 0,
        'Salvation::AnyNotify::Plugin::Daemon' => 0,
        'Salvation::AnyNotify' => '0.01',
        'AnyEvent' => 0,
        'Sub::Recursive' => 0,
        'Twiggy' => 0,
        'Plack' => 0,
    },
    META_MERGE => {
    "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/kainwinterheart/salvation-anynotify-server.git',
                web => 'https://github.com/kainwinterheart/salvation-anynotify-server',
                bugtracker => 'https://github.com/kainwinterheart/salvation-anynotify-server/issues',
            },
        },
    },
);

exit 0;

__END__

use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Salvation::AnyNotify::Plugin::Daemon',
    VERSION_FROM => 'lib/Salvation/AnyNotify/Plugin/Daemon.pm',
    ABSTRACT => 'Daemon plugin for Salvation::AnyNotify',
    AUTHOR => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
    LICENSE => 'mit',
    PREREQ_PM => {
        'Salvation::Method::Signatures' => '0.02',
        'Salvation::DaemonDecl' => 0,
        'Salvation::AnyNotify' => '0.01',
    },
    META_MERGE => {
    "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/kainwinterheart/salvation-anynotify-daemon.git',
                web => 'https://github.com/kainwinterheart/salvation-anynotify-daemon',
                bugtracker => 'https://github.com/kainwinterheart/salvation-anynotify-daemon/issues',
            },
        },
    },
);

exit 0;

__END__

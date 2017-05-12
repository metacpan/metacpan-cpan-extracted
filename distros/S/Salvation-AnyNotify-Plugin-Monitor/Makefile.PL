use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Salvation::AnyNotify::Plugin::Monitor',
    VERSION_FROM => 'lib/Salvation/AnyNotify/Plugin/Monitor.pm',
    ABSTRACT => 'Monitor plugin for Salvation::AnyNotify',
    AUTHOR => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
    LICENSE => 'mit',
    PREREQ_PM => {
        'Salvation::TC' => '0.11',
        'Salvation::Method::Signatures' => '0.02',
        'Salvation::AnyNotify::Plugin::Daemon' => 0,
        'Salvation::AnyNotify::Plugin::Server' => 0,
        'Salvation::AnyNotify' => '0.01',
        'URI' => 0,
        'LWP::Simple' => 0,
    },
    META_MERGE => {
    "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/kainwinterheart/salvation-anynotify-monitor.git',
                web => 'https://github.com/kainwinterheart/salvation-anynotify-monitor',
                bugtracker => 'https://github.com/kainwinterheart/salvation-anynotify-monitor/issues',
            },
        },
    },
);

exit 0;

__END__

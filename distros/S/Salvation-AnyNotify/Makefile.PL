use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Salvation::AnyNotify',
    VERSION_FROM => 'lib/Salvation/AnyNotify.pm',
    ABSTRACT => 'Notification framework',
    AUTHOR => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
    LICENSE => 'mit',
    PREREQ_PM => {
        'Salvation::TC' => '0.11',
        'Salvation::Method::Signatures' => '0.02',
        'Salvation::PluginCore' => '0.01',
        'YAML' => 0,
        'File::Slurp' => 0,
        'File::HomeDir' => 0,
    },
    META_MERGE => {
    "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/kainwinterheart/salvation-anynotify.git',
                web => 'https://github.com/kainwinterheart/salvation-anynotify',
                bugtracker => 'https://github.com/kainwinterheart/salvation-anynotify/issues',
            },
        },
    },
);

exit 0;

__END__

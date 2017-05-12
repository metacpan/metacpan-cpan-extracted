use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Salvation::DaemonDecl',
    VERSION_FROM => 'lib/Salvation/DaemonDecl.pm',
    ABSTRACT => 'Yet another daemon maker',
    AUTHOR => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
    LICENSE => 'mit',
    PREREQ_PM => {
        boolean => 0,
        'Salvation::TC' => '0.11',
        'Salvation::Method::Signatures' => '0.02',
        'Sub::Prototype' => 0,
        'B::Hooks::EndOfScope' => 0,
        'AnyEvent' => 0,
    },
    META_MERGE => {
    "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/kainwinterheart/salvation-daemondecl.git',
                web => 'https://github.com/kainwinterheart/salvation-daemondecl',
                bugtracker => 'https://github.com/kainwinterheart/salvation-daemondecl/issues',
            },
        },
    },
);

exit 0;

__END__

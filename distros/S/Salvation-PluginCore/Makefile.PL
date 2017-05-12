use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Salvation::PluginCore',
    VERSION_FROM => 'lib/Salvation/PluginCore.pm',
    ABSTRACT => 'A little plugin framework',
    AUTHOR => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
    LICENSE => 'mit',
    PREREQ_PM => {
        'Salvation::TC' => '0.11',
        'Salvation::Method::Signatures' => '0.02',
        'String::CamelCase' => 0,
    },
    META_MERGE => {
    "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/kainwinterheart/salvation-plugincore.git',
                web => 'https://github.com/kainwinterheart/salvation-plugincore',
                bugtracker => 'https://github.com/kainwinterheart/salvation-plugincore/issues',
            },
        },
    },
);

exit 0;

__END__

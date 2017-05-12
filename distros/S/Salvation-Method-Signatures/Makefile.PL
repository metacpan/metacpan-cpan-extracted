use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Salvation::Method::Signatures',
    VERSION_FROM => 'lib/Salvation/Method/Signatures.pm',
    ABSTRACT => 'Yet another method signatures system',
    AUTHOR => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
    LICENSE => 'mit',
    PREREQ_PM => {
        boolean => 0,
        'Devel::Declare' => 0,
        'Salvation::TC' => '0.12',
        'Module::Load' => 0,
        'Salvation::UpdateGvFLAGS' => 0,
        B => 0,
    },
    META_MERGE => {
    "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/kainwinterheart/salvation-method-signatures.git',
                web => 'https://github.com/kainwinterheart/salvation-method-signatures',
            },
            bugtracker => 'https://github.com/kainwinterheart/salvation-method-signatures/issues',
        },
    },
);

exit 0;

__END__

use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => "Sub::Identify",
    ABSTRACT        => 'Retrieve names of code references',
    VERSION_FROM    => "lib/Sub/Identify.pm",
    LICENSE         => 'perl',
    PREREQ_PM       => {
        'Test::More'    => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/rgs/Sub-Identify.git',
                web  => 'https://github.com/rgs/Sub-Identify',
            },
        },
    },
);

use ExtUtils::MakeMaker;
use 5.008;

WriteMakefile(
    AUTHOR          => 'Rafael Garcia-Suarez <rgs@consttype.org>',
    NAME	    => "Sub::Current",
    ABSTRACT        => "Get the current subroutine",
    VERSION_FROM    => "lib/Sub/Current.pm",
    LICENSE         => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/rgs/p5-Sub-Current.git',
                web  => 'https://github.com/rgs/p5-Sub-Current',
            },
        },
    },
);

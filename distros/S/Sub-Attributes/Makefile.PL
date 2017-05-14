use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Sub::Attributes',
    VERSION_FROM   => 'lib/Sub/Attributes.pm',
    PREREQ_PM      => { 'Test::More' => 0, 'Test::Fatal' => 0 },
    ABSTRACT_FROM  => 'lib/Sub/Attributes.pm',
    AUTHOR         => 'David Farrell',
    INC            => '-I.',
    LICENSE        => 'freebsd',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => 'https://github.com/dnmfarrell/Sub-Attributes/issues',
            repository => {
                type => 'git',
                url  => 'https://github.com/dnmfarrell/Sub-Attributes.git',
                web  => 'https://github.com/dnmfarrell/Sub-Attributes',
            },
        }})
     : ()
    ),
);

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Net::Nessus::REST',
    VERSION_FROM   => 'lib/Net/Nessus/REST.pm',
    ABSTRACT_FROM  => 'lib/Net/Nessus/REST.pm',
    LICENSE        => 'GPL_3',
    PREREQ_PM => {
        'JSON'           => 0,
        'LWP::UserAgent' => 6.04,
    },
    TEST_REQUIRES  => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            repository => {
                type => 'git',
                url  => 'git://github.com/guillomovitch/Net-Nessus-REST',
                web  => 'https://github.com/guillomovitch/Net-Nessus-REST'
            },
        }
    }
);

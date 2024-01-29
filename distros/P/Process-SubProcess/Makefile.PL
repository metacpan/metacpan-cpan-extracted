use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Process::SubProcess',
    ABSTRACT_FROM => 'lib/Process/SubProcess.pm',
    LICENSE       => 'perl',
    AUTHOR        => 'Bodo (Hugo) Barwich <b.barwich@hotmail.com>',
    VERSION_FROM  => 'lib/Process/SubProcess.pm',

    # VERSION     => '2.0.2',
    MIN_PERL_VERSION => '5.010',
    test             => { TESTS => 't/*.t' },
    EXE_FILES        => ['bin/run_subprocess.pl'],
    BUILD_REQUIRES   => {
        'ExtUtils::MakeMaker' => '6.46',
    },
    TEST_REQUIRES => {
        'Test::More'    => '0',
        'Capture::Tiny' => '0'
    },
    PREREQ_PM => {
        'Getopt::Long::Descriptive' => '0',
        'Path::Tiny'                => '0',
        'JSON'                      => '0',
        'YAML'                      => '0',
        'Data::Dump'                => '0',
        'Time::HiRes'               => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bodo-hugo-barwich/Process.git',
                web  => 'https://github.com/bodo-hugo-barwich/Process',
            },
            bugtracker => {
                web => 'https://github.com/bodo-hugo-barwich/Process/issues'
            },
        },
    },
);


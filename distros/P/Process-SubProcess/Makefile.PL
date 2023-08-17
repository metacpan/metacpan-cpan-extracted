use ExtUtils::MakeMaker::CPANfile;
 


WriteMakefile(
    NAME             => 'Process::SubProcess',
    ABSTRACT_FROM    => 'lib/Process/SubProcess.pm',
    LICENSE          => 'perl',
    AUTHOR           => 'Bodo (Hugo) Barwich <b.barwich@hotmail.com>',
    VERSION_FROM     => 'lib/Process/SubProcess.pm',
#    VERSION     => '2.0.2',
    MIN_PERL_VERSION => '5.010',
    test             => {TESTS => 't/*.t'},
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
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


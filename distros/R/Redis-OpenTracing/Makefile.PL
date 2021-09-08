use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'Redis::OpenTracing',
    'VERSION_FROM'  => 'lib/Redis/OpenTracing.pm',
    'ABSTRACT_FROM' => 'lib/Redis/OpenTracing.pod',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/*.t',
    },
);

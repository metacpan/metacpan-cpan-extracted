use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'OpenTracing::Implementation::NoOp',
    'VERSION_FROM'  => 'lib/OpenTracing/Implementation/NoOp.pm',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/*.t t/Implementation/NoOp/*/*.t',
    },
);
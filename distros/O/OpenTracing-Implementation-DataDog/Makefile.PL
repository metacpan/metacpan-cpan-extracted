use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'OpenTracing::Implementation::DataDog',
    'VERSION_FROM'  => 'lib/OpenTracing/Implementation/DataDog.pm',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/*.t t/*/*.t',
    },
);

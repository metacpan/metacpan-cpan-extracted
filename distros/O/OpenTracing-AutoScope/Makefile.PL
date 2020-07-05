use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'OpenTracing::AutoScope',
    'VERSION_FROM'  => 'lib/OpenTracing/AutoScope.pm',
    'ABSTRACT_FROM' => 'lib/OpenTracing/AutoScope.pod',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/*.t t/WrapScope/*.t',
    },
);

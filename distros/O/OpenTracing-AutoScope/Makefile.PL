use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'OpenTracing::AutoScope',
    'VERSION_FROM'  => 'lib/OpenTracing/AutoScope.pm',
    'ABSTRACT_FROM' => 'lib/OpenTracing/AutoScope.pod',
    'LICENSE'       => 'perl',
    'EXE_FILES'     => ['bin/opentracing_wrapscope_generator'],
    test            => {
        TESTS       => 't/*.t t/WrapScope/*.t  t/WrapScope/ConfigGenerator/*.t',
    },
);

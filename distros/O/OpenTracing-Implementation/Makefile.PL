use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'OpenTracing::Implementation',
    'VERSION_FROM'  => 'lib/OpenTracing/Implementation.pm',
    'LICENSE'       => 'perl',
    
    'test'          => {
        TESTS           => 't/*.t t/Interface/Bootstrap/*.t',
    },
    
);

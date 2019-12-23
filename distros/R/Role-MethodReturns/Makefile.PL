use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'Role::MethodReturns',
    'VERSION_FROM'  => 'lib/Role/MethodReturns.pm',
    'LICENSE'       => 'artistic2',
    
    test => {
        'TESTS'         => 't/*.t',
    },
    
);
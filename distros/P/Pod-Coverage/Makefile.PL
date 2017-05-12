use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'Pod::Coverage',
    'VERSION_FROM' => 'lib/Pod/Coverage.pm',
    'PREREQ_PM' => {
        'Devel::Symdump' => '2.01',
        'Pod::Find' => '0.21',
        'Pod::Parser' => '1.13',
        'Test::More' => '0'
    },
    'EXE_FILES' => [
        'bin/pod_cover',
    ],
);

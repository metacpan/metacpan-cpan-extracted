use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Pod::Index',
    'VERSION_FROM'	=> 'lib/Pod/Index.pm',
    'EXE_FILES'         => [qw( podindex )],
    'PREREQ_PM'		=> {
        Search::Dict => 0,
        Pod::Parser  => 1,
        #Test::Pod    => 1.20, # for testing
    },
);


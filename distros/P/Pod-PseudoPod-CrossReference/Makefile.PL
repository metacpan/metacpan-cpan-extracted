use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Pod::PseudoPod::CrossReference',
    VERSION_FROM => 'lib/Pod/PseudoPod/CrossReference.pm',    # finds $VERSION
    PREREQ_PM => {
                  'Test::More'     => 0,
                  'Pod::PseudoPod' => 0.11,
    },

    #    EXE_FILES    => [ ''  ],
    AUTHOR   => 'Timothy Appnel (tima@perl.org)',
    ABSTRACT =>
"a framework for extracting information from PseudoPOD files for cross-referencing",
    PL_FILES => {},    # ignore the Build.PL file
);

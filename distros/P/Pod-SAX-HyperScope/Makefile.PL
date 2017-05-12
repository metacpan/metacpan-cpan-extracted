use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Pod::SAX::HyperScope',
    VERSION_FROM => 'lib/Pod/SAX/HyperScope.pm',
    EXE_FILES => ['bin/pod2hs'],
    PREREQ_PM => {
        'XML::SAX::Base' => 0,
        'Pod::SAX' => 0,
        'HTML::Entities' => 0,
    },
);

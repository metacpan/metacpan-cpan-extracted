use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Package::New',
    VERSION_FROM => 'lib/Package/New.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/Package/New.pm',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Devel::Hide'  => 0,
                    },
);

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'String::ProperCase::Surname',
    VERSION_FROM => 'lib/String/ProperCase/Surname.pm',
    ABSTRACT_FROM=> 'lib/String/ProperCase/Surname.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    PREREQ_PM    => {
                     'strict'       => 0,
                     'warnings'     => 0,
                     'Test::Simple' => 0.44,
                    },
);

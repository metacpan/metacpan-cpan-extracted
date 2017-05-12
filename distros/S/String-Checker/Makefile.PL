use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'String::Checker',
    'VERSION_FROM' => 'Checker.pm',
    'PREREQ_PM'    => { 'Date::Manip' => 0 },
);

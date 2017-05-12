#!perl -w
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Debian317061',
    PREREQ_PM      => {
        'Not::A::Real::Module' => 42,
    },
   );
0;

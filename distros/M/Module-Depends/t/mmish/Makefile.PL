#!perl -w
use ExtUtils::MakeMaker;
WriteMakefile(
    PREREQ_PM      => {
        'Not::A::Real::Module' => 42,
    },
   );

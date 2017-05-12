#!perl -w
use ExtUtils::MakeMaker;
use FindBin qw($Bin);
WriteMakefile(
    PREREQ_PM      => {
        'Not::A::Real::Module' => 42,
    },
   );

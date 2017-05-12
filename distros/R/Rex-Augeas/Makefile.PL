use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Rex-Augeas',
   VERSION_FROM => 'lib/Rex/Augeas.pm',
   PREREQ_PM => {'Rex' => '0.7.0', 'Config::Augeas' => 0},
   LICENSE => 'perl'
);


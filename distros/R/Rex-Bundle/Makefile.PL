use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Rex::Bundle',
   VERSION_FROM => 'lib/Rex/Bundle.pm',
   PREREQ_PM => {'Rex' => '0.0.7', 'version' => '0.77'},
   LICENSE => 'perl'
);


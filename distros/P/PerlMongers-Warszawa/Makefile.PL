use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'PerlMongers::Warszawa',
    'VERSION_FROM' => 'Warszawa.pm', # finds $VERSION
    'PREREQ_PM'     => { 'Perldoc' => 0.2, 'Exporter' => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => '£ukasz Strzelecki <strzelec@rswsystems.pl>') : ()),
);

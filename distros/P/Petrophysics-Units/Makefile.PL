use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Petrophysics::Units',
    'VERSION_FROM'	=> 'Units.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'PM'		=> {
	'Units.pm' => '$(INST_LIBDIR)/Units.pm',
	'units_database.inc' => '$(INST_LIBDIR)/units_database.inc'},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Units.pm', # retrieve abstract from module
       AUTHOR     => 'Bjarne Steinsbo <bosteins@broadpark.no>') : ()),
);

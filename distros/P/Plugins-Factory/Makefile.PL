use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Plugins::Factory',
    VERSION_FROM      => 'lib/Plugins/Factory.pm', # finds $VERSION
    PREREQ_PM         => {
    	Module::Load => 0,
    	Module::Pluggable => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Plugins/Factory.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Sivirinov') : ()),
);

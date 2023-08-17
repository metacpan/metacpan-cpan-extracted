use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SignalWire::CompatXML',
    VERSION_FROM      => 'lib/SignalWire/CompatXML.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SignalWire/CompatXML.pm', # retrieve abstract from module
       AUTHOR         => 'Scott Wiersdorf <scott@perlcode.org>') : ()),
);

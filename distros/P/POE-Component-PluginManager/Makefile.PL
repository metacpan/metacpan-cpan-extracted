use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Component::PluginManager',
    VERSION_FROM      => 'lib/POE/Component/PluginManager.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => {
    POE => 0.9999,
    Class::Unload => 0.03,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POE/Component/PluginManager.pm', # retrieve abstract from module
       AUTHOR         => 'whoppix <elektronenvolt@quantentunnel.de>') : ()),
);

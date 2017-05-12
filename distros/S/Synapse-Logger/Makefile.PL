use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Synapse::Logger',
    VERSION_FROM => './lib/Synapse/Logger.pm',
    PREREQ_PM    => {},
);

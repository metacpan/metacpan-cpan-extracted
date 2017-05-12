use 5.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PDLDM::Rank',
    VERSION_FROM      => 'lib/PDLDM/Rank.pm', # finds $VERSION
	CONFIGURE_REQUIRES => {"PDL" => 0,}, # e.g., Module::Name => 1.1
    PREREQ_PM         => {"PDL" => 0}, # e.g., Module::Name => 1.1    
    ABSTRACT_FROM  => 'lib/PDLDM/Rank.pm', # retrieve abstract from module
    AUTHOR         => 'Muthuthanthiri B Thilak L Fernando',
	LICENSE           => 'perl',
	MIN_PERL_VERSION => '5.0',
);

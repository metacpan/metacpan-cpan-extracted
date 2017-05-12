use 5.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PDLDM::Common',
    VERSION_FROM      => 'lib/PDLDM/Common.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    CONFIGURE_REQUIRES => {"PDL" => 0,}, # e.g., Module::Name => 1.1
    PREREQ_PM         => {"PDL" => 0,
			  "Math::Random::MT::Auto" => 0,
			  "Text::CSV" => 0,}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/PDLDM/Common.pm', # retrieve abstract from module
    AUTHOR            => 'Muthuthanthiri B Thilak L Fernando',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);

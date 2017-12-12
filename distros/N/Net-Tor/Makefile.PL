use 5.026001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Tor',
    AUTHOR            => 'Klaus Ethgen <Klaus@Ethgen.de>',
    VERSION_FROM      => 'lib/Net/Tor.pm',
    ABSTRACT_FROM     => 'lib/Net/Tor.pm',
    LICENSE           => 'gpl',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
);

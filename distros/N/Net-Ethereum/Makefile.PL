use 5.022000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Ethereum',
    VERSION_FROM      => 'lib/Net/Ethereum.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
#    ABSTRACT_FROM     => 'lib/Net/Ethereum.pm', # retrieve abstract from module
    AUTHOR            => 'Alexandre Frolov <frolov@itmatrix.ru>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);

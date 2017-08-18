use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::pWhoIs',
    VERSION_FROM      => 'lib/Net/pWhoIs.pm',
    PREREQ_PM         => {
        Socket           => 0,
        IO::Socket::INET => 0,
        Scalar::Util     => 0,
    },
    ABSTRACT_FROM     => 'lib/Net/pWhoIs.pm', # retrieve abstract from module
    AUTHOR            => 'Matthew Hersant <matt_hersant@yahoo.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);

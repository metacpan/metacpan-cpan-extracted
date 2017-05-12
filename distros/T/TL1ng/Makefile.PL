use 5.008000;   # Minimum perl version to which this module will install.
use ExtUtils::MakeMaker;

# See perldoc ExtUtils::MakeMaker for details of how to 
# influence the contents of the Makefile that is written.

WriteMakefile(
    NAME          => 'TL1ng',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/TL1ng.pm', # Extracts $VERSION from this file.
    PREREQ_PM     => {
        Net::Telnet => '3.03', 
        Time::Local => '1.17',
    },
    ( $] >= 5.005  ## Add these new keywords supported since 5.005 
      ? (     
         AUTHOR         => 'Steve Scaffidi <sscaffidi@cpan.net>',
         ABSTRACT_FROM  => 'lib/TL1ng.pm', # Extract the abstract from the POD
                                           # in this file. The expected format 
                                           # is "<MODULE::NAME> - <Abstract>"
                                           # as the first text line under the 
                                           # "=head1 NAME" section header.
        ) 
      : ()
    ),
);

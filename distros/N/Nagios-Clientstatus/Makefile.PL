

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Nagios::Clientstatus',
    VERSION_FROM => 'lib/Nagios/Clientstatus.pm', # finds \$VERSION
    AUTHOR       => 'Richard Lippmann (horshack@lisa.franken.de)',
    ABSTRACT     => 'Framework for Nagios check-service programs',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Getopt::Long' => 2.34,
                     'Data::Dumper' => undef,
                     'Log::Log4perl' => undef,
                    },
);

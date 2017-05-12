

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::Twitter::Stream',
    VERSION_FROM => 'Stream.pm',
    AUTHOR       => 'Martin Redmond (@martinredmond)',
    ABSTRACT     => 'Connect to the Twitter streaming api',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'JSON' => 2.0,
                    },
);

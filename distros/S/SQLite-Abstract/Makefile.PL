

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SQLite::Abstract',
    VERSION_FROM => 'lib/SQLite/Abstract.pm', # finds \$VERSION
    AUTHOR       => 'Vidul Nikolaev Petrov (vidul@cpan.org)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
					 'Test::More' => 0.01,
					 'DBI' => 1.48,
					 'DBD::SQLite2' => 0.01,
                    },
);

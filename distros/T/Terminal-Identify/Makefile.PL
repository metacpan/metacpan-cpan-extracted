use 5.030000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Terminal::Identify',
    VERSION_FROM      => 'lib/Terminal/Identify.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Inline::C' => '0.82', 'POSIX' => '1.88'}, # e.g., Module::Name => 1.1
    ABSTRACT          => 'Perl extension for identifying the terminal emulator',
    # ABSTRACT_FROM   => 'lib/Terminal/Identify.pm', # retrieve abstract from module
    AUTHOR            => 'Dr. Peter Netz <ztenretep@cpan.org>',
    LICENSE           => 'perl',
    # Value must be from legacy list of licenses here
    # http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);

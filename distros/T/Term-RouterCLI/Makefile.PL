use 5.8.8;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME            => 'Term::RouterCLI',
    VERSION_FROM    => 'lib/Term/RouterCLI.pm', # finds $VERSION
    ABSTRACT        => 'Classes for building a Router (Standford) style CLI',
    PREREQ_PM       => {
            'Config::General'           => 2.50,
            'Digest::SHA'               => 5.62,
            'Env'                       => 1.00,
            'FileHandle'                => 2.01,
            'Log::Log4perl'             => 1.33,
            'parent'                    => 0.221,
            'POSIX'                     => 1.09,
            'Sys::Syslog'               => 0.29,
            'Term::ReadKey'             => 2.30,
            'Term::ReadLine::Gnu'       => 1.20,
            'Test::More'                => 0.98,
            'Test::Output'              => 1.01,
            'Text::Shellwords::Cursor'  => 0.81,
    },
    AUTHOR          => 'Bret Jordan',
);

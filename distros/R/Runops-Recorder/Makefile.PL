use ExtUtils::MakeMaker;

use 5.010;

WriteMakefile(
    NAME            => 'Runops::Recorder',
    VERSION_FROM    => 'lib/Runops/Recorder.pm', # finds $VERSION
    PREREQ_PM       => {
        accessors::ro   => 0,
        Term::ReadKey   => 0,
        Term::Screen    => 0,
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM   => 'lib/Runops/Recorder.pm', # retrieve abstract from module
    AUTHOR          => 'Claes Jakobsson <claesjac@cpan.org>',
    EXE_FILES       => [qw(bin/rr-viewer bin/rr-diff bin/rr-exceptions)],
);

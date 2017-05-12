use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile (
    NAME            => 'Proc::PID::File',
    VERSION_FROM    => 'File.pm',
    AUTHOR          => 'Erick Calder <ecalder@cpan.org>',
    ABSTRACT        => 'A module to manage PID files',
    META_MERGE      => {
        resources => {
            repository => 'https://github.com/dtikhonov/Proc-PID-File',
        },
    },
);

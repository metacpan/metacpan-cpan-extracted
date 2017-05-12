use 5.008006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Module::Versions',
    VERSION_FROM => 'lib/Module/Versions.pm',                 # finds $VERSION
    PREREQ_PM    => { IO::Handle => 1, Data::Dumper => 1 },
    (   $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT_FROM =>
                'lib/Module/Versions.pm',    # retrieve abstract from module
            AUTHOR => 'Thomas Walloschke <thw@cpan.org>.'
            )
        : ()
    ),
);

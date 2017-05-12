use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Module::Optional',
    VERSION_FROM => 'lib/Module/Optional.pm', # finds $VERSION
    AUTHOR       => 'Ivor Williams ()',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
    LICENSE      => 'perl',
);

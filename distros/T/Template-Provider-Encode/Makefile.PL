use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Provider::Encode',
    VERSION_FROM      => 'lib/Template/Provider/Encode.pm', # finds $VERSION
    PREREQ_PM         => {
        'Template::Provider' => 0,
        'Encode' => 0,
    }, 
);

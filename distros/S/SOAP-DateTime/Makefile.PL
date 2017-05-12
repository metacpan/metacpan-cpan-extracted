use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SOAP::DateTime',
    VERSION_FROM => 'lib/SOAP/DateTime.pm', # finds $VERSION
    AUTHOR       => 'Joe McMahon (mcmahon@ibiblio.org)',
    ABSTRACT     => 'Convert dates into xsd:dateTime format',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Date::Manip' =>0,
                    },
);

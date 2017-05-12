

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'String::EscapeCage',
    VERSION_FROM => 'lib/String/EscapeCage.pm', # finds \$VERSION
    AUTHOR       => 'Mark P Sullivan ()',
    ABSTRACT_FROM=> 'lib/String/EscapeCage.pm', # finds ^($package\s-\s)(.*)
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);



use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'String::Sprintf',
    VERSION_FROM => 'lib/String/Sprintf.pm', # finds \$VERSION
    AUTHOR       => 'Bart Lateur (bart.lateur@pandora.be)',
    ABSTRACT     => 'Custom overloading of sprintf',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);

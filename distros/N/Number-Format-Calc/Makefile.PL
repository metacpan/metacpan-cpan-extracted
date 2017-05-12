use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Number::Format::Calc',
    VERSION_FROM => 'lib/Number/Format/Calc.pm', # finds $VERSION
    AUTHOR       => 'Markus Holzer (HOLLIHO@gmx.de)',
    ABSTRACT     => 'Number::Format::Calc',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);

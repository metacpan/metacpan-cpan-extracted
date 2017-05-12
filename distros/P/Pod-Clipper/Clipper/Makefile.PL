

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Pod::Clipper',
    VERSION_FROM => 'lib/Pod/Clipper.pm', # finds \$VERSION
    AUTHOR       => 'Yousef H. Alhashemi (yousef.alhashemi@gmail.com)',
    ABSTRACT     => 'Extract blocks of POD from a document',
    PREREQ_PM    => {
                     'Test::More' => 0.44,
                     'Pod::Clipper::Block' => 0.01,
                     'Text::Trim' => undef,
                    },
);

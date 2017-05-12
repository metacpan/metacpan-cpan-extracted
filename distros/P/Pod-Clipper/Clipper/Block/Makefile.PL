

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Pod::Clipper::Block',
    VERSION_FROM => 'lib/Pod/Clipper/Block.pm', # finds \$VERSION
    AUTHOR       => 'Yousef H. Alhashemi (yha@cpan.org)',
    ABSTRACT     => 'A block of POD or non-POD data',
    PREREQ_PM    => {
                     'Test::More' => 0.44,
                    },
);



use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Promise::AsyncAwait',
    VERSION_FROM => 'lib/Promise/AsyncAwait.pm', # finds \$VERSION
    AUTHOR       => 'Felipe Gasper (FELIPE)',
    ABSTRACT_FROM => 'lib/Promise/AsyncAwait.pm',
    LICENSE      => 'perl_5',
    PREREQ_PM    => {
                     'Promise::XS' => 0.13,
                     'Future::AsyncAwait' => 0.47,
                     'Test::More' => 0,
                     'Test::FailWarnings' => 0,
                    },
);

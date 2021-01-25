use strict;
use warnings;
use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME         => 'Pod::Modifier',
    AUTHOR       => q{Udhav Verma <vermaudh@cpan.org>},
    VERSION_FROM => 'lib/Pod/Modifier.pm',
    ABSTRACT     => 'Modify/ add to an existing POD dynamically',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Pod::Perldoc::ToTerm'  =>  3.28,
        'File::Slurp'  =>  9999.19,
        'Pod::Select'  =>  1.60,
        'Module::Util'  =>  1.09,
    },
    TEST_REQUIRES => {
          'Test::More'    => 0.98,
    },
);

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
        NAME => 'Test::Dist2',
        VERSION_FROM => 'lib/Test/Dist2.pm',
        PREREQ_PM => {
            'Foo' => 0,
        }
);

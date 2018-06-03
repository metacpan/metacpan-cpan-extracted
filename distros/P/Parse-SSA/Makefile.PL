use 5.10.0;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Parse::SSA',
    VERSION_FROM      => 'lib/Parse/SSA.pm',
    PREREQ_PM         => {
        'strict'                => 0,
        'warnings'              => 0,
    },
    "ABSTRACT" => 'SSA/ASS Parser',
    AUTHOR            => 'Konstantin Gromyko <disinterpreter@protonmail.ch>',
    LICENSE           => 'perl',
    META_MERGE          => {
        requires        => {
            perl    => '5.10.0'
        }
    }
);

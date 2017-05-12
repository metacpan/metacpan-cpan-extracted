use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Term::ProgressBar::Simple',
    'VERSION_FROM' => 'lib/Term/ProgressBar/Simple.pm',
    'PREREQ_PM'    => {                                   #
        'Term::ProgressBar::Quiet' => 0,
    },
);

require 5.008001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Pots',
    AUTHOR          => 'Remy Chibois (rchibois@free.fr)',
    ABSTRACT        => 'Perl ObjectThreads - OO modules for ithreads',
    VERSION_FROM    => 'lib/Pots/SharedObject.pm',
    PREREQ_PM       => {
        'Storable' => 0
    }
);

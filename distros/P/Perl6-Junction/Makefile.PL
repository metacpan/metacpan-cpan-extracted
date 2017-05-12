use 5.000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Perl6::Junction',
    AUTHOR        => 'Carl Franks',
    ABSTRACT_FROM => 'lib/Perl6/Junction.pm',
    VERSION_FROM  => 'lib/Perl6/Junction.pm',
    LICENSE       => 'perl',
    PREREQ_PM     => {
                     Carp       => 0,
                     Test::More => 0,
    },
);


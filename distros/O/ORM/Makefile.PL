use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
(
    NAME              => 'ORM',
    VERSION_FROM      => 'lib/ORM.pm',
    PREREQ_PM         =>
    {
        'DBD::SQLite'              => 1.11,
        'Class::Data::Inheritable' => 0.02,
        'Exception::Class'         => 1.20,
    },
    (
        $] >= 5.005
        ? ## Add these new keywords supported since 5.005
        (
            ABSTRACT       => 'ORM - Powerful object-relational mapper for Perl.',
            AUTHOR         => 'Alexey V. Akimov'
        )
        : ()
    ),
);

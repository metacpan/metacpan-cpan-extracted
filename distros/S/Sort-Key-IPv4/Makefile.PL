
use ExtUtils::MakeMaker;

WriteMakefile( NAME              => 'Sort::Key::IPv4',
               VERSION_FROM      => 'lib/Sort/Key/IPv4.pm',
               PREREQ_PM         => { Sort::Key => 1.28 },
               ABSTRACT_FROM  => 'lib/Sort/Key/IPv4.pm',
               AUTHOR         => 'Salvador Fandino <sfandino@yahoo.com>' );

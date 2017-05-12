
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Sort::Key::OID',
               VERSION_FROM => 'lib/Sort/Key/OID.pm',
               PREREQ_PM => { Sort::Key => '1.28' },
               ABSTRACT_FROM => 'lib/Sort/Key/OID.pm',
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>' );

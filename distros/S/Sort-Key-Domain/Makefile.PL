use ExtUtils::MakeMaker;

WriteMakefile( NAME           => 'Sort::Key::Domain',
               VERSION_FROM   => 'lib/Sort/Key/Domain.pm',
               PREREQ_PM      => { 'Sort::Key' => '0' },
               ABSTRACT_FROM  => 'lib/Sort/Key/Domain.pm',
               AUTHOR         => 'Salvador Fandiño <sfandino@yahoo.com>',
               INC            => '-I.' );

use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Proc::Queue',
               VERSION_FROM => 'lib/Proc/Queue.pm',
               ABSTRACT_FROM => 'lib/Proc/Queue.pm',
               AUTHOR => 'Salvador Fandiño <sfandino@yahoo.com>',
               # LICENSE => 'perl',
               PREREQ_PM => { Test::More => 0} );

use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Sort::Key::Top',
               VERSION_FROM => 'lib/Sort/Key/Top.pm',
               PREREQ_PM => { 'Test::More' => 0 },
               ABSTRACT_FROM  => 'lib/Sort/Key/Top.pm',
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS => [''], # e.g., '-lm'
               DEFINE => '', # e.g., '-DHAVE_SOMETHING'
               INC => '-I.', # e.g., '-I. -I/usr/include/other'
               # OPTIMIZE => '-g -O0'
             );

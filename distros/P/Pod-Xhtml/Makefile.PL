use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Pod::Xhtml',
              VERSION_FROM  => 'lib/Pod/Xhtml.pm',
              EXE_FILES     => ['scripts/pod2xhtml'],
              PREREQ_PM => {
                            Pod::Parser => 0,
                            Pod::ParseUtils => 0,
                            Test::More => 0,
                            Test::Assertions::TestScript => 0,
                            URI::Escape => 0,
                           },
              ABSTRACT_FROM => 'lib/Pod/Xhtml.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );

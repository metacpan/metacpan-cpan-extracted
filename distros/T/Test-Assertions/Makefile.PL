use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Test::Assertions',
              VERSION_FROM  => 'lib/Test/Assertions.pm',
              PREREQ_PM => {
                            Carp => 0,
                            Log::Trace => 0,
                            Getopt::Long => 0,
                           },
              ABSTRACT_FROM => 'lib/Test/Assertions.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );

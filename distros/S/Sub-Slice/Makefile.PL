use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Sub::Slice',
              VERSION_FROM  => 'lib/Sub/Slice.pm',
              PREREQ_PM => {
              					'Log::Trace' => 0,
              					'Test::Assertions' => 0,              					
                           },
              ABSTRACT_FROM => 'lib/Sub/Slice.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );

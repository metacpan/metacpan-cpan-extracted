use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'SQL::Shell',
              VERSION_FROM  => 'lib/SQL/Shell.pm',
              EXE_FILES => ['bin/sqlsh'],
              PREREQ_PM => {
				DBI => 0,
				URI::Escape => 0,
				Log::Trace => 0,
				Test::Assertions => 0,
				Test::Assertions::TestScript => 0,
				IO::CaptureOutput => 0,
				IO::Scalar => 0,
                           },
              ABSTRACT_FROM => 'lib/SQL/Shell.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );

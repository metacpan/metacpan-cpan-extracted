use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Spectrum::CLI',
    'VERSION_FROM' => 'CLI.pm', # finds $VERSION
    PM             => {
			 'CLI.pm' => '$(INST_LIBDIR)/CLI.pm',
		      },
    EXE_FILES      => [
			 'CreateUsers',
			 'DatabaseTally',
			 'ShowModels',
			 'UserReport'
                      ],
    clean          => { FILES => '$(EXE_FILES)' },
    dist => {
       'COMPRESS' =>  'gzip',
       'SUFFIX' => 'gz'
    }
);

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME              => 'Regexp::DeferredExecution',
	      VERSION_FROM      => 'lib/Regexp/DeferredExecution.pm',
	      PREREQ_PM         => {
				    Text::Balanced => undef
				   },
	      ($] >= 5.005 ?
	       (AUTHOR          => 'Aaron J. Mackey <amackey@virginia.edu>'
	       ) : ()
	      ),
);

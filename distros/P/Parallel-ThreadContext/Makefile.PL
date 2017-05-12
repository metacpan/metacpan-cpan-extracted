use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Parallel::ThreadContext',
    'VERSION_FROM'	=> 'Parallel::ThreadContext', # finds $VERSION
    'PREREQ_PM'		=> { threads => 0,
			     threads::shared => 0 }, # e.g., Module::Name => 1.1
   );

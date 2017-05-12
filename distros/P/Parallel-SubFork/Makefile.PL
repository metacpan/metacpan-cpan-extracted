use 5.006001;

use ExtUtils::MakeMaker;

WriteMakefile(

	NAME         => 'Parallel::SubFork',
	VERSION_FROM => 'lib/Parallel/SubFork.pm',

	PREREQ_PM => {
		# Runtime dependencies
		Carp                  => 0,
		POSIX                 => 0,
		Class::Accessor::Fast => 0,

		# For testig purposes
		Test::More            => 0,
		Test::Pod             => 0,
		IPC::SysV             => 0,
		IPC::Semaphore        => 0,
		FindBin               => 0,
	},
	

	ABSTRACT_FROM => 'lib/Parallel/SubFork.pm',
	AUTHOR        => 'Emmanuel Rodriguez <emmanuel.rodriguez@gmail.com>',
);

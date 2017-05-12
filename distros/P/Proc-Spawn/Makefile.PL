use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'         => 'Proc::Spawn',
	      'VERSION_FROM' => 'Spawn.pm',
	      'PREREQ_PM'    => { 'POSIX'      => 0,
				  'Exporter'   => 0,
				  'IO'         => 0,
				  'IO::Handle' => 0,
				  'IO::Pty'    => 0,
				},
);

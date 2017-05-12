use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Statistics::Shannon',
	VERSION_FROM	=> 'lib/Statistics/Shannon.pm',
	PREREQ_PM	=> { 'Statistics::Frequency' => '0.04' },
	dist		=> { 'COMPRESS' => 'gzip' }
);

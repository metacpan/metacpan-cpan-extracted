use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Statistics::DEA',
	VERSION_FROM	=> 'lib/Statistics/DEA.pm',
	dist		=> { 'COMPRESS' => 'gzip' }
);

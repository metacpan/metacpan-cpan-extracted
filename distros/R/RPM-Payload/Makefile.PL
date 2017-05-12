use ExtUtils::MakeMaker;
WriteMakefile 
	NAME		=> 'RPM::Payload',
	VERSION_FROM	=> 'lib/RPM/Payload.pm',
	ABSTRACT_FROM	=> 'lib/RPM/Payload.pm',
	AUTHOR		=> 'Alexey Tourbin <at@altlinux.org>',
	dist		=> { COMPRESS => 'gzip -9nf' },
	;

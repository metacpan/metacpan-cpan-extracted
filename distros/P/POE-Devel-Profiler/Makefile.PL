use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=>	'POE::Devel::Profiler',
	'VERSION_FROM'	=>	'lib/POE/Devel/Profiler.pm', # finds $VERSION
	'PREREQ_PM'	=>	{
		'POE'	=>	'0.29',
	},
	'EXE_FILES'	=>	[ 'bin/poepp' ],
	( $] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(	'ABSTRACT_FROM'	=>	'lib/POE/Devel/Profiler.pm', # retrieve abstract from module
			'AUTHOR'	=> 'Apocalypse <APOCAL@cpan.org>') : ()),
);

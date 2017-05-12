use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Software::Packager::Svr4',
	'VERSION_FROM'	=> 'lib/Software/Packager/Svr4.pm',
	'AUTHOR'	=> 'Mark A. Hershberger <mah@everybody.org>',
	'PREREQ_PM'	=> {
		'Software::Packager'	=>	'0.07',
		},
	'clean'		=> {
		'FILES'	=> 'Sun1-+Tes t/svr4_tmp_build_dir',
		},
);

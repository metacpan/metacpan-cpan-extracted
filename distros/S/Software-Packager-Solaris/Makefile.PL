use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Software::Packager::Solaris',
	'VERSION_FROM'	=> 'lib/Software/Packager/Solaris.pm',
	'AUTHOR'	=> 'R Bernard Davison (rbdavison@cpan.org)',
	'ABSTRACT'	=> 'This module extends Software::Packager providing the ability to create packages for the Solaris platform.',
	'PREREQ_PM'	=> {
		'Software::Packager'	=>	'0.07',
		},
	'clean'		=> {
		'FILES'	=> 'Sun1-+Tes t/solaris_tmp_build_dir',
		},
);

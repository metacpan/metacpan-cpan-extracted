use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Software::Packager::Aix',
	'VERSION_FROM'	=> 'lib/Software/Packager/Aix.pm',
	'AUTHOR'	=> 'R Bernard Davison (rbdavison@cpan.org)',
	'ABSTRACT'	=> 'This module extends Software::Packager providing the ability to create packages for the AIX platform.',
	'PREREQ_PM'	=> {
		'Software::Packager'	=>	'0.09',
		},
       	'clean'         => {
               	'FILES' => '*/*/*/*~ */*/*/*/*~ *.tar *.tar.gz t/aix_tmp_build_dir *.bff',
               	},
);

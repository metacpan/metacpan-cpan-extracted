use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Software::Packager::Darwin',
	'VERSION_FROM'	=> 'lib/Software/Packager/Darwin.pm',
	'AUTHOR'	=> 'R Bernard Davison (rbdavison@cpan.org)',
	'ABSTRACT'	=> 'This module extends Software::Packager providing the ability to create packages for MacOS X.',
	'PREREQ_PM'	=> {
		'Software::Packager'	=>	'0.06',
		},
	'clean'		=> {
		'FILES'	=> 'MacOSXTestPackage.pkg',
		},
);
